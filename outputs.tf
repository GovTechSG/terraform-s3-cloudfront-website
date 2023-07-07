output "acm_arn" {
  description = "ARN of acm certificate"
  value       = aws_acm_certificate.cert.arn
}

output "cache_invalidation_command" {
  description = "CloudFront edge cache invalidation command. /path/to/invalidation/resource is like /index.html /error.html"
  value       = "aws cloudfront create-invalidation  --distribution-id ${aws_cloudfront_distribution.web_dist.id} --paths /path/to/invalidation/resource"
}

output "cache_invalidation_redirect_command" {
  description = "CloudFront edge cache invalidation command. /path/to/invalidation/resource is like /index.html /error.html"
  value       = "aws cloudfront create-invalidation  --distribution-id ${aws_cloudfront_distribution.web_redirect.id} --paths /path/to/invalidation/resource"
}

output "cloudfront_distribution_main_arn" {
  description = "ARN of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_dist.arn
}

output "cloudfront_distribution_main_domain_name" {
  description = "Domain URL of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_dist.domain_name
}

output "cloudfront_distribution_main_etag" {
  description = "ETag of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_dist.etag
}

output "cloudfront_distribution_main_hosted_zone_id" {
  description = "hosted zone id of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_dist.hosted_zone_id
}

output "cloudfront_distribution_redirect_arn" {
  description = "ARN of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_redirect.arn
}

output "cloudfront_distribution_redirect_domain_name" {
  description = "Domain URL of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_redirect.domain_name
}

output "cloudfront_distribution_redirect_etag" {
  description = "ETag of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_redirect.etag
}

output "cloudfront_distribution_redirect_hosted_zone_id" {
  description = "hosted zone id of cloudfront distribution"
  value       = aws_cloudfront_distribution.web_redirect.hosted_zone_id
}

output "s3_main_arn" {
  description = "ARN of s3 hosting index.html of site"
  value       = aws_s3_bucket.main.arn
}

output "s3_redirect_arn" {
  description = "ARN of s3 hosting redirection to www."
  value       = aws_s3_bucket.redirect.arn
}

output "s3_main_website_endpoint" {
  value = aws_s3_bucket_website_configuration.main.website_endpoint
}

output "s3_main_website_domain" {
  value = aws_s3_bucket_website_configuration.main.website_domain
}

output "s3_redirec_website_endpoint" {
  value = aws_s3_bucket_website_configuration.redirect.website_endpoint
}

output "s3_redirect_website_domain" {
  value = aws_s3_bucket_website_configuration.redirect.website_domain
}

output "aws_cloudfront_response_headers_policy_cors_config" {
  value = aws_cloudfront_response_headers_policy.web_dist.cors_config
}

output "aws_cloudfront_response_headers_policy_custom_headers_config" {
  value = aws_cloudfront_response_headers_policy.web_dist.custom_headers_config
}

output "aws_cloudfront_response_headers_policy_security_headers_config" {
  value = aws_cloudfront_response_headers_policy.web_dist.security_headers_config
}
