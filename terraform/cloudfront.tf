resource "aws_s3_bucket" "docusaurus" {
  bucket = "handson-docusaurus"
}

resource "aws_s3_bucket_acl" "docusaurus" {
  bucket = aws_s3_bucket.docusaurus.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "docusaurus" {
  bucket                  = aws_s3_bucket.docusaurus.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "docusaurus" {
  bucket = aws_s3_bucket.docusaurus.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

locals {
  s3_origin_id = "handson-docusaurus.s3.ap-northeast-1.amazonaws.com"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  default_root_object = "index.html"
  origin {
    domain_name              = aws_s3_bucket.docusaurus.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.docusaurus.id
    origin_id                = aws_cloudfront_origin_access_control.docusaurus.name
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = []

  default_cache_behavior {
    compress         = true
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_cloudfront_origin_access_control.docusaurus.name
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    viewer_protocol_policy = "allow-all"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_control" "docusaurus" {
  name                              = "handson-docusaurus.s3.ap-northeast-1.amazonaws.com"
  description                       = "handson-docusaurus"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "docusaurus" {
  bucket = "handson-docusaurus"
  policy = jsonencode(
    {
      Id = "PolicyForCloudFrontPrivateContent"
      Statement = [
        {
          Action = "s3:GetObject"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
            }
          }
          Effect = "Allow"
          Principal = {
            Service = "cloudfront.amazonaws.com"
          }
          Resource = "${aws_s3_bucket.docusaurus.arn}/*"
          Sid      = "AllowCloudFrontServicePrincipal"
        },
      ]
      Version = "2008-10-17"
    }
  )
}
