resource "aws_s3_bucket" "main" {
  bucket = var.domain_names[0]
  policy = data.aws_iam_policy_document.bucket_policy.json

  // acl = "private"
  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "s3/${var.domain_names[0]}/"
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "redirect" {
  bucket = var.redirect_domain_names[0]
  policy = data.aws_iam_policy_document.bucket_policy_redirect.json
  acl    = "private"

  website {
    redirect_all_requests_to = aws_s3_bucket.main.id
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = var.s3_logging_bucket
    target_prefix = "s3/${var.redirect_domain_names[0]}/"
  }

  versioning {
    enabled = true
  }
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "AllowCloudFront"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.domain_names[0]}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_access_identity.id}"]
    }
  }
}

data "aws_iam_policy_document" "bucket_policy_redirect" {
  statement {
    sid    = "AllowCloudFront"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::${var.redirect_domain_names[0]}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_access_identity_redirect.id}"]
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
