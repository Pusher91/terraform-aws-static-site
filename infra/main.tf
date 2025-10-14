terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "us-east-1" }
provider "aws" { alias = "us_east_1" region = "us-east-1" }

module "site" {
  # If your module repo is named differently, update the URL below.
  source = "git::https://github.com/YOUR_ORG/terraform-aws-static-site.git?ref=v1.0.0"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name    = var.domain_name
  aliases        = var.aliases
  hosted_zone_id = var.hosted_zone_id
  price_class    = var.price_class
  enable_logs    = var.enable_logs
}

