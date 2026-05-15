### Provider as AWS used and version is 6.45.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.45.0"
    }

    random = {
      source = "hashicorp/random"
    }
  }
}

### Provider configuration and region assigned by variable. Default value is ap-south-1
provider "aws" {
  region = var.aws_region
}

### Creating random ID for bucket name so that bucket name becomes globally unique
resource "random_id" "bucket_id" {
  byte_length = 4
}

### Creating S3 bucket for static website files with random ID
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "portfolio-website-${random_id.bucket_id.hex}"
}

### Enabling static website hosting on S3 bucket
### suffix means index document is index.html
### When we access the website, S3 will look for index.html and display the content
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website_bucket.id

  index_document {
    suffix = "index.html"
  }
}

/*
Configuring Public Access Block for S3 bucket.

By default, S3 blocks public access.
For static website hosting, we are setting these values to false
so that public bucket policy can allow users to read website files.
*/
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

### Creating bucket policy for S3 bucket
### This policy allows everyone to read website files using s3:GetObject
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id

  depends_on = [
    aws_s3_bucket_public_access_block.public_access_block
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static_website_bucket.arn}/*"
      }
    ]
  })
}

/*
Uploading website files to S3 bucket.

Source folder is www.
All files inside www folder will be uploaded to S3.
It will also maintain the same folder structure inside S3 bucket.
*/
resource "aws_s3_object" "website_files" {
  for_each = fileset("${path.module}/www", "**/*")

  bucket = aws_s3_bucket.static_website_bucket.id
  key    = each.value
  source = "${path.module}/www/${each.value}"
  etag   = filemd5("${path.module}/www/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

/*
Creating CloudFront distribution for S3 static website.

CloudFront will use S3 website endpoint as origin.
It will provide HTTPS, caching, better speed, and low latency.
Default root object is index.html.
*/
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.static_website_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}