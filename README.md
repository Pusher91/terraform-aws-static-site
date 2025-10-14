# terraform-aws-static-site

Terraform module: S3 (private) + CloudFront (OAC) + ACM (us-east-1) + Route53 A/AAAA records for a static site. Optimized for GitHub Actions deployments that upload to S3 and invalidate CloudFront.

## Features
- S3 origin locked to CloudFront via OAC (no public access)
- ACM certificate with DNS validation (or use an existing ARN)
- CloudFront aliases, IPv6, HTTP/2+3
- Optional SPA fallback (403/404 → /index.html)
- Optional CloudFront standard logs to S3
- Route53 A/AAAA aliases for all hostnames

## Usage
```hcl
provider "aws" { region = "us-east-1" }
provider "aws" { alias = "us_east_1" region = "us-east-1" }

module "site" {
  source         = "git::https://github.com/YOUR_ORG/terraform-aws-static-site.git?ref=v1.0.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name    = "example.com"
  aliases        = ["www.example.com"]
  hosted_zone_id = "Z123EXAMPLE"

  # Optional
  enable_spa                 = true
  response_headers_policy_id = null
  enable_logs                = false
  tags = { project = "static-site" }
}

output "bucket"        { value = module.site.bucket_name }
output "distribution"  { value = module.site.distribution_id }
output "cf_domain"     { value = module.site.distribution_domain_name }
output "certificate"   { value = module.site.certificate_arn }

