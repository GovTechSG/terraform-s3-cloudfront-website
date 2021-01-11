provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "cert" {
  provider                  = aws.us-east-1
  domain_name               = var.domain_names[0]
  subject_alternative_names = distinct(concat(slice(var.domain_names, 1, length(var.domain_names)), var.redirect_domain_names))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.enable_acm_validation ? 1 : 0
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = aws_route53_record.cert_validation.*.fqdn
}