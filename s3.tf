data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "main" {
  bucket = var.domain_names[0]
  // acl = "private"
}
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.bucket
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.bucket

  target_bucket = var.s3_logging_bucket
  target_prefix = "s3/${var.domain_names[0]}/"
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "redirect" {
  bucket = var.redirect_domain_names[0]
}
resource "aws_s3_bucket_acl" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  acl    = "private"
}

resource "aws_s3_bucket_policy" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  policy = data.aws_iam_policy_document.bucket_policy_redirect.json
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket

  redirect_all_requests_to {
    host_name = var.domain_names[0]
    protocol  = "https"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_logging" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket

  target_bucket = var.s3_logging_bucket
  target_prefix = "s3/${var.redirect_domain_names[0]}/"
}

resource "aws_s3_bucket_versioning" "redirect" {
  bucket = aws_s3_bucket.redirect.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  # statement {
  #   sid    = "AllowCloudFront"
  #   effect = "Allow"
  #   actions = [
  #     "s3:GetObject"
  #   ]
  #   resources = [
  #     "arn:aws:s3:::${var.domain_names[0]}/*"
  #   ]

  #   principals {
  #     type        = "AWS"
  #     identifiers = ["arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_access_identity.id}"]
  #   }
  # }

  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.domain_names[0]}/*"
    ]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.web_dist.id}"]
    }
  }

  statement {
    sid = "https-only"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.domain_names[0]}",
      "arn:aws:s3:::${var.domain_names[0]}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = [false]
    }
  }
}

data "aws_iam_policy_document" "bucket_policy_redirect" {
  # statement {
  #   sid    = "AllowCloudFrontServicePrincipalReadOnly"
  #   effect = "Allow"
  #   actions = [
  #     "s3:GetObject"
  #   ]
  #   resources = [
  #     "arn:aws:s3:::${var.redirect_domain_names[0]}/*"
  #   ]
  #   principals {
  #     type        = "Service"
  #     identifiers = ["cloudfront.amazonaws.com"]
  #   }

  #   condition {
  #     test     = "StringEquals"
  #     variable = "AWS:SourceArn"
  #     values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.web_redirect.id}"]
  #   }
  # }

  statement {
    sid = "https-only"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect = "Deny"

    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.redirect_domain_names[0]}",
      "arn:aws:s3:::${var.redirect_domain_names[0]}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = [false]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block_redirect" {
  bucket = aws_s3_bucket.redirect.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "public_access_block_main" {
  bucket = aws_s3_bucket.main.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = [
      "Authorization",
      "Content-Length"
    ]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}
