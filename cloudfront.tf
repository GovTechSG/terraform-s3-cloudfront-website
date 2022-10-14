locals {
  s3_origin_id          = "${var.domain_names[0]}${var.cloudfront_origin_path}"
  s3_redirect_origin_id = "${var.redirect_domain_names[0]}${var.cloudfront_origin_path}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "website"
}

resource "aws_cloudfront_response_headers_policy" "web_dist" {
  name = "${var.service_name}-policy"

  security_headers_config {
    content_security_policy {
      content_security_policy = var.content_security_policy
      override                = false
    }

    xss_protection {
      mode_block = true
      override   = false
      protection = true
    }

    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      override                   = false
      preload                    = true
    }

    content_type_options {
      override = false
    }

    referrer_policy {
      referrer_policy = "same-origin"
      override        = false
    }

    frame_options {
      frame_option = "DENY"
      override     = false
    }
  }
}

resource "aws_cloudfront_distribution" "web_dist" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.service_name
  default_root_object = "index.html"
  price_class         = "PriceClass_200"
  aliases             = var.domain_names
  web_acl_id          = var.web_acl_id

  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    origin_path = var.cloudfront_origin_path

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  # SPA
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  dynamic "logging_config" {
    for_each = var.save_access_log ? { "dummy" : "dummy" } : {}

    content {
      include_cookies = true
      bucket          = "${var.s3_logging_bucket}.s3.amazonaws.com"
      prefix          = "cloudfront/${var.domain_names[0]}"
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    cached_methods             = ["GET", "HEAD", "OPTIONS"]
    target_origin_id           = local.s3_origin_id
    compress                   = true
    response_headers_policy_id = aws_cloudfront_response_headers_policy.web_dist.id

    forwarded_values {
      query_string = var.forward_query_string
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = var.main_default_ttl
    max_ttl                = 86400

    dynamic "lambda_function_association" {
      for_each = var.lambda_function_associations
      content {
        event_type = lambda_function_association.key
        lambda_arn = lambda_function_association.value
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    iterator = behavior
    content {
      path_pattern               = behavior.value["path"]
      target_origin_id           = local.s3_origin_id
      allowed_methods            = ["GET", "HEAD", "OPTIONS"]
      cached_methods             = ["GET", "HEAD", "OPTIONS"]
      viewer_protocol_policy     = "redirect-to-https"
      response_headers_policy_id = aws_cloudfront_response_headers_policy.web_dist.id

      forwarded_values {
        query_string = var.forward_query_string
        headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

        cookies {
          forward = "none"
        }
      }

      min_ttl     = 0
      default_ttl = var.main_default_ttl
      max_ttl     = 86400

      dynamic "function_association" {
        for_each = behavior.value["function-associations"]
        iterator = func
        content {
          event_type   = func.key
          function_arn = func.value
        }
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}



resource "aws_cloudfront_distribution" "web_redirect" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = var.service_name
  price_class     = "PriceClass_200"
  aliases         = var.redirect_domain_names
  web_acl_id      = var.web_acl_id

  origin {
    domain_name = aws_s3_bucket.redirect.website_endpoint
    origin_id   = local.s3_redirect_origin_id
    custom_origin_config {
      http_port  = 80
      https_port = 80

      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  dynamic "logging_config" {
    for_each = var.save_access_log ? { "dummy" : "dummy" } : {}

    content {
      include_cookies = true
      bucket          = "${var.s3_logging_bucket}.s3.amazonaws.com"
      prefix          = "cloudfront/${var.redirect_domain_names[0]}"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_redirect_origin_id
    compress         = true

    forwarded_values {
      query_string = var.forward_query_string
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.redirect.qualified_arn
      include_body = true
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
