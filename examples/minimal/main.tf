terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "site" {
  source = "../.."

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name    = "example.com"
  aliases        = ["www.example.com"]
  hosted_zone_id = "Z123EXAMPLE"

  enable_spa  = true
  enable_logs = false
}

output "bucket_name"               { value = module.site.bucket_name }
output "distribution_id"           { value = module.site.distribution_id }
output "distribution_domain_name"  { value = module.site.distribution_domain_name }
output "certificate_arn"           { value = module.site.certificate_arn }

