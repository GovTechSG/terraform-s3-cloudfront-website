resource "aws_route53_record" "www" {
  count   = var.route53_zone_id != "" ? length(var.domain_names) : 0
  zone_id = var.route53_zone_id
  name    = var.domain_names[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web_dist.domain_name
    zone_id                = aws_cloudfront_distribution.web_dist.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "redirect" {
  count   = var.route53_zone_id != "" ? length(var.redirect_domain_names) : 0
  zone_id = var.route53_zone_id
  name    = var.redirect_domain_names[count.index]
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.web_redirect.domain_name
    zone_id                = aws_cloudfront_distribution.web_redirect.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count   = var.enable_acm_validation ? length(var.domain_names) : 0
  name    = lookup(tolist(aws_acm_certificate.cert.domain_validation_options)[count.index], "resource_record_name")
  type    = lookup(tolist(aws_acm_certificate.cert.domain_validation_options)[count.index], "resource_record_type")
  records = [lookup(tolist(aws_acm_certificate.cert.domain_validation_options)[count.index], "resource_record_value")]
  zone_id = var.route53_zone_id
  ttl     = 60

  lifecycle {
    ignore_changes = ["fqdn"]
  }
}