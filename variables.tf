variable "domain_name" {
  description = "Primary DNS name (apex or subdomain) served by CloudFront."
  type        = string
}

variable "aliases" {
  description = "Additional hostnames (SANs) on the certificate and CloudFront aliases, e.g., [\"www.example.com\"]."
  type        = list(string)
  default     = []
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for DNS validation and A/AAAA records."
  type        = string
}

variable "bucket_name" {
  description = "Optional S3 bucket name. Defaults to domain_name with dots replaced by dashes."
  type        = string
  default     = null
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_100","PriceClass_200","PriceClass_All"], var.price_class)
    error_message = "price_class must be one of PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "minimum_tls_version" {
  description = "Minimum TLS protocol for viewer connections."
  type        = string
  default     = "TLSv1.2_2021"
}

variable "default_root_object" {
  description = "Default root object."
  type        = string
  default     = "index.html"
}

variable "enable_ipv6" {
  description = "Create AAAA records and enable IPv6 on the distribution."
  type        = bool
  default     = true
}

variable "enable_logs" {
  description = "Enable CloudFront standard logs to an S3 bucket."
  type        = bool
  default     = false
}

variable "logs_bucket_name" {
  description = "Optional existing bucket for CloudFront logs. If null and enable_logs=true, a logs bucket will be created."
  type        = string
  default     = null
}

variable "cache_policy_id" {
  description = "CloudFront cache policy ID. Default = AWS Managed-CachingOptimized."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "response_headers_policy_id" {
  description = "Optional CloudFront response headers policy ID (e.g., AWS managed security headers)."
  type        = string
  default     = null
}

variable "enable_spa" {
  description = "Map 403/404 to 200 with SPA index."
  type        = bool
  default     = false
}

variable "spa_redirect_path" {
  description = "Path served for SPA fallback."
  type        = string
  default     = "/index.html"
}

variable "spa_error_codes" {
  description = "HTTP error codes to remap for SPA."
  type        = list(number)
  default     = [403, 404]
}

variable "allowed_methods" {
  description = "Allowed methods."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cached_methods" {
  description = "Cached methods."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "s3_force_destroy" {
  description = "Allow terraform to destroy non-empty S3 bucket (useful in dev)."
  type        = bool
  default     = true
}

variable "enable_bucket_versioning" {
  description = "Enable S3 bucket versioning for the site bucket."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "Use an existing ACM certificate (in us-east-1). If null, the module will create/validate one."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "canonical_host" {
  description = "If set, redirect to this host (e.g., secretsocietyrecipes.com)."
  type        = string
  default     = null
}
variable "force_https" {
  description = "Redirect http->https."
  type        = bool
  default     = true
}
variable "enable_clean_urls" {
  description = "Rewrite /path and /path/ to /path/index.html."
  type        = bool
  default     = true
}
