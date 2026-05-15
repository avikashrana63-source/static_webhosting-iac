output "website-url" {
    value = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}
output "s3-website-name" {
    value = random_id.bucket_id.hex
}