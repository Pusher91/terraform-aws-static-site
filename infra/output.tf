variable "domain_name"    { type = string }
variable "hosted_zone_id" { type = string }
variable "aliases"        { type = list(string) default = [] }
variable "price_class"    { type = string default = "PriceClass_100" }
variable "enable_logs"    { type = bool   default = true }

# For GitHub OIDC role trust policy
variable "aws_account_id" { type = string }
variable "github_repo"    { type = string } # e.g., "YOUR_ORG/YOUR_REPO"

