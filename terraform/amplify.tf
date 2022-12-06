locals {
  # Create access token : https://github.com/settings/tokens
  github_access_token = "ghp_XXXXXXXX"
}

resource "aws_amplify_app" "docusaurus" {
  name         = "sandbox-docusaurus"
  repository   = "https://github.com/mayuki12/sandbox-docusaurus"
  access_token = local.github_access_token

  # The default build_spec added by the Amplify Console for React.
  build_spec = <<-EOT
        version: 1
        frontend:
          phases:
            preBuild:
              commands:
                - npm install
            build:
              commands: 
                - npm run build
          artifacts:
            baseDirectory: /build
            files:
              - '**/*'
    EOT

  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }


}
