# Install dependencies and create archive
resource "null_resource" "nonce_injector_deps" {
  triggers = {
    package_json = filemd5("${path.module}/lambda/nonce-injector/package.json")
    source_code  = filemd5("${path.module}/lambda/nonce-injector/index.js")
  }

  provisioner "local-exec" {
    command = <<EOT
      cd ${path.module}/lambda/nonce-injector && \
      npm install --production
    EOT
  }


}

data "archive_file" "nonce_injector" {
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

resource "aws_iam_role_policy_attachment" "lambda_edge_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_edge.name
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
  provider         = aws.us-east-1  # Lambda@Edge must be in us-east-1
  filename         = data.archive_file.nonce_injector.output_path
  function_name    = "${var.service_name}-nonce-injector-new"
  role            = aws_iam_role.lambda_edge.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.nonce_injector.output_base64sha256
  runtime         = "nodejs20.x"
  publish         = true  # Required for Lambda@Edge

  memory_size = 128
  timeout     = 5
}

resource "aws_cloudwatch_log_group" "nonce_injector" {
  provider = aws.us-east-1  # Must be in the same region as the Lambda function
  name              = "/aws/lambda/us-east-1.${aws_lambda_function.nonce_injector.function_name}"
  retention_in_days = 14  # Retain logs for 14 days
}
