variable "service_name" {
  description = "tagged with service name"
}

variable "enable_acm_validation" {
  description = "Validates ACM by updating route 53 DNS"
  type        = bool
  default     = false
}

variable "domain_names" {
  description = "domain names to serve site on"
  type        = list(string)
}

variable "redirect_domain_names" {
  description = "domain names to redirect to `domain_names`"
  type        = list(string)
}

variable "cloudfront_origin_path" {
  default     = ""
  description = "Origin path of CloudFront"
}

variable "route53_zone_id" {
  description = "Route53 Zone ID"
  type        = string
  default     = ""
}

variable "save_access_log" {
  description = "whether save cloudfront access log to S3"
  type        = bool
  default     = false
}

variable "lambda_function_associations" {
  description = "CloudFront Lambda function associations. key is CloudFront event type and value is lambda function ARN with version. For nonce injection, this is automatically populated with the nonce-injector Lambda."
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = []
}

variable "s3_logging_bucket" {
  description = "Bucket which will store s3 access logs"
  type        = string
  default     = ""
}

variable "s3_logging_bucket_prefix" {
  description = "Bucket which will store s3 access logs"
  type        = string
  default     = ""
}

variable "permissions_boundary" {
  description = "If provided, all IAM roles will be created with this permissions boundary attached."
  type        = string
  default     = ""
}

variable "main_default_ttl" {
  description = "default TTL of the main cloudfront distribution"
  default     = 180
  type        = number
}

variable "web_acl_id" {
  description = "WAF ACL to attach to the cloudfront distribution"
  default     = ""
  type        = string
}

variable "ordered_cache_behaviors" {
  description = ""
  default     = []
  type = list(object({
    path                  = string
    function-associations = map(string)
  }))
}

variable "forward_query_string" {
  description = "forward query strings to origin"
  default     = false
  type        = bool
}

variable "content_security_policy" {
  description = "Formatted CSP in string"
  default     = "default-src 'none';"
  type        = string
}

variable "enable_compression" {
  description = "Toggle whether the default cache behaviour has compression enabled"
  default     = true
  type        = bool
}
