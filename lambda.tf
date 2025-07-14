# Generate Lambda function code from template
resource "local_file" "nonce_injector" {
  count = var.enable_nonce ? 1 : 0
  content = templatefile("${path.module}/lambda/nonce-injector/index.js.tpl", {
    inject_script_nonces = var.nonce_injection_config.inject_script_nonces
    inject_style_nonces  = var.nonce_injection_config.inject_style_nonces
  })
  filename = "${path.module}/lambda/nonce-injector/index.js"
}

# Install dependencies and create archive
resource "null_resource" "nonce_injector_deps" {
  count = var.enable_nonce ? 1 : 0
  triggers = {
    package_json = filemd5("${path.module}/lambda/nonce-injector/package.json")
    source_code  = local_file.nonce_injector[0].content_base64sha256
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/lambda/nonce-injector && npm install
    EOT
  }

  depends_on = [local_file.nonce_injector]
}

data "archive_file" "nonce_injector" {
  count = var.enable_nonce ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda/nonce-injector"
  output_path = "${path.module}/lambda/nonce-injector.zip"

  depends_on = [null_resource.nonce_injector_deps]
}

resource "aws_iam_role" "lambda_edge" {
  name = "${var.service_name}-lambda-edge"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  permissions_boundary = var.permissions_boundary != "" ? var.permissions_boundary : null
}

resource "aws_iam_role_policy" "lambda_edge_logs" {
  count = var.enable_nonce ? 1 : 0
  name  = "${var.service_name}-lambda-edge-logs"
  role  = aws_iam_role.lambda_edge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/lambda/us-east-1.${var.service_name}-nonce-injector*",
          "arn:aws:logs:*:*:log-group:/aws/lambda/${var.service_name}-nonce-injector*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_edge_s3" {
  name = "${var.service_name}-lambda-edge-s3"
  role = aws_iam_role.lambda_edge.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.main.arn}",
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_lambda_function" "nonce_injector" {
  count = var.enable_nonce ? 1 : 0
  provider         = aws.us-east-1  # Lambda@Edge must be in us-east-1
  filename         = data.archive_file.nonce_injector[0].output_path
  function_name    = "${var.service_name}-nonce-injector"
  role            = aws_iam_role.lambda_edge.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.nonce_injector[0].output_base64sha256
  runtime         = "nodejs20.x"
  publish         = true  # Required for Lambda@Edge

  memory_size = 128
  timeout     = 5
}
