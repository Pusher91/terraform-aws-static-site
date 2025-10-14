locals {
  aliases_all  = distinct(concat([var.domain_name], var.aliases))
  bucket_name  = coalesce(var.bucket_name, replace(var.domain_name, ".", "-"))
  logs_bucket  = var.logs_bucket_name != null ? var.logs_bucket_name : "${local.bucket_name}-logs"
}

# --- Site bucket (private; access only via CloudFront OAC) ---
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = var.s3_force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = var.enable_bucket_versioning ? "Enabled" : "Suspended"
  }
}

# --- Optional CloudFront logs bucket ---
resource "aws_s3_bucket" "logs" {
  count         = var.enable_logs && var.logs_bucket_name == null ? 1 : 0
  bucket        = local.logs_bucket
  force_destroy = true
  tags          = var.tags
}

# For CloudFront standard logs, keep ACLs enabled; use BucketOwnerPreferred
resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.enable_logs && var.logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = var.enable_logs && var.logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Allow CloudFront log delivery service to write logs
data "aws_iam_policy_document" "logs" {
  count = var.enable_logs && var.logs_bucket_name == null ? 1 : 0
  statement {
    sid     = "AWSCloudFrontLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    resources = ["arn:aws:s3:::${aws_s3_bucket.logs[0].bucket}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid     = "AWSCloudFrontLogDeliveryAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    resources = ["arn:aws:s3:::${aws_s3_bucket.logs[0].bucket}"]
  }
}

resource "aws_s3_bucket_policy" "logs" {
  count  = var.enable_logs && var.logs_bucket_name == null ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.logs[0].json
}

# --- OAC for CloudFront to S3 origin ---
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.domain_name}-oac"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --- ACM certificate in us-east-1 (for CloudFront) ---
# Root module MUST pass providers { aws = aws, aws.us_east_1 = aws.us_east_1 }
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1
  count             = var.certificate_arn == null ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = var.aliases
  tags = var.tags
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.certificate_arn == null ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}
  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  count                   = var.certificate_arn == null ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

locals {
  cert_arn = var.certificate_arn != null ? var.certificate_arn : aws_acm_certificate_validation.cert[0].certificate_arn
}

# --- CloudFront distribution ---
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  aliases             = local.aliases_all
  default_root_object = var.default_root_object
  price_class         = var.price_class
  comment             = "Static site for ${var.domain_name}"
  http_version        = "http2and3"

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.site.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = var.allowed_methods
    cached_methods         = var.cached_methods
    compress               = true
    cache_policy_id        = var.cache_policy_id
    response_headers_policy_id = var.response_headers_policy_id
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = local.cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_tls_version
  }

  dynamic "custom_error_response" {
    for_each = var.enable_spa ? toset(var.spa_error_codes) : []
    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = var.spa_redirect_path
      error_caching_min_ttl = 0
    }
  }

  dynamic "logging_config" {
    for_each = var.enable_logs ? [1] : []
    content {
      bucket = var.logs_bucket_name != null ? "${var.logs_bucket_name}.s3.amazonaws.com" : aws_s3_bucket.logs[0].bucket_domain_name
      include_cookies = false
      prefix = "cloudfront/"
    }
  }

  tags = var.tags
}

# --- S3 bucket policy: allow only this distribution (OAC) to read objects ---
data "aws_iam_policy_document" "site" {
  statement {
    sid = "AllowCloudFrontServicePrincipalRead"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cdn.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site.json
}

# --- Route53 A/AAAA alias records for all hostnames ---
resource "aws_route53_record" "alias_a" {
  for_each = toset(local.aliases_all)
  zone_id  = var.hosted_zone_id
  name     = each.value
  type     = "A"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_aaaa" {
  for_each = var.enable_ipv6 ? toset(local.aliases_all) : []
  zone_id  = var.hosted_zone_id
  name     = each.value
  type     = "AAAA"
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_function" "mkdocs_router" {
  name    = replace("mkdocs-router-${var.domain_name}", "/[^a-zA-Z0-9-_]/", "-")
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = templatefile("${path.module}/cloudfront/mkdocs_router.js", {})
  # If you ever change code and need a new name quickly, tack on a suffix.
}

# Attach on viewer-request when any feature is enabled
locals {
  need_router_fn = var.enable_clean_urls || var.canonical_host != null || var.force_https
}

# In your existing aws_cloudfront_distribution.cdn default_cache_behavior block, add:
# (showing just the new dynamic)
# ...
default_cache_behavior {
  # existing settings...
  cache_policy_id             = var.cache_policy_id
  response_headers_policy_id  = var.response_headers_policy_id

  dynamic "function_association" {
    for_each = local.need_router_fn ? [1] : []
    content {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.mkdocs_router.arn
    }
  }
}

