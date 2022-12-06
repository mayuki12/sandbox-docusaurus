locals {
  github_repository_id = "mayuki12/sandbox-docusaurus"
}

resource "aws_codepipeline" "docusaurus" {
  name     = "handson-docusaurus"
  role_arn = aws_iam_role.docusaurus_codepipeline.arn

  artifact_store {
    location = "codepipeline-ap-northeast-1-643954177045"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      category = "Source"
      configuration = {
        "BranchName"           = "main"
        "ConnectionArn"        = aws_codestarconnections_connection.docusaurus_codepipeline.arn
        "FullRepositoryId"     = local.github_repository_id
        "OutputArtifactFormat" = "CODE_ZIP"
      }
      input_artifacts = []
      name            = "Source"
      namespace       = "SourceVariables"
      output_artifacts = [
        "SourceArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeStarSourceConnection"
      region    = "ap-northeast-1"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Build"

    action {
      category = "Build"
      configuration = {
        "ProjectName" = aws_codebuild_project.docusaurus_build.name
      }
      input_artifacts = [
        "SourceArtifact",
      ]
      name      = "Build"
      namespace = "BuildVariables"
      output_artifacts = [
        "BuildArtifact",
      ]
      owner     = "AWS"
      provider  = "CodeBuild"
      region    = "ap-northeast-1"
      run_order = 1
      version   = "1"
    }
  }
  stage {
    name = "Deploy"

    action {
      category = "Deploy"
      configuration = {
        "BucketName" = "handson-docusaurus"
        "Extract"    = "true"
      }
      input_artifacts = [
        "BuildArtifact",
      ]
      name             = "Deploy"
      namespace        = "DeployVariables"
      output_artifacts = []
      owner            = "AWS"
      provider         = "S3"
      region           = "ap-northeast-1"
      run_order        = 1
      version          = "1"
    }
  }
}

resource "aws_codebuild_project" "docusaurus_build" {
  name         = "build-docusaurus"
  service_role = aws_iam_role.docusaurus_codebuild.arn

  artifacts {
    encryption_disabled    = false
    name                   = "build-docusaurus"
    override_artifact_name = false
    packaging              = "NONE"
    type                   = "CODEPIPELINE"
  }

  cache {
    modes = []
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  source {
    buildspec           = <<-EOT
            version: 0.2
            phases:
              install:
                commands:
                   - npm install
              build:
                commands:
                   - npm run build
            artifacts:
              files:
                 - '**/*'
              name: artifact
              #discard-paths: yes
              base-directory: build/
        EOT
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
}

resource "aws_iam_role" "docusaurus_codepipeline" {
  name = "AWSCodePipelineServiceRole-ap-northeast-1-handson-docusaurus"
  path = "/service-role/"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codepipeline.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )

  inline_policy {
    name   = "AWSCodePipelineServiceRole-build-docusaurus-ap-northeast-1"
    policy = file("${path.module}/template/codepipeline_iam_policy.json")
  }
}

resource "aws_iam_role" "docusaurus_codebuild" {
  name = "codebuild-build-docusaurus-service-role"
  path = "/service-role/"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "codebuild.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )

  inline_policy {
    name   = "CodeBuildBasePolicy-test-2022-ap-northeast-1"
    policy = file("${path.module}/template/codepipeline_iam_policy.json")
  }
}

resource "aws_codestarconnections_connection" "docusaurus_codepipeline" {
  name          = "handson-docusaurus"
  provider_type = "GitHub"
}

