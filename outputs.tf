output "bucket_name" {
  description = "S3 bucket name for site content."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "S3 bucket ARN."
  value       = aws_s3_bucket.site.arn
}

output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = aws_cloudfront_distribution.cdn.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name."
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = aws_cloudfront_distribution.cdn.arn
}

output "certificate_arn" {
  description = "ACM certificate ARN used by CloudFront."
  value       = local.cert_arn
}

