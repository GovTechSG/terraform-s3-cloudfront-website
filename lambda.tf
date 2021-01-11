resource "local_file" "redirect-template" {
  content = templatefile(
    "${path.module}/redirect-lambda/template/redirect.js",
    { redirect_to = var.domain_names[0]}
  )
  filename = "${path.module}/redirect-lambda/redirect.js"
}


data "archive_file" "redirect_zip" {
  depends_on = [
    local_file.redirect-template
  ]
  type        = "zip"
  output_path = "${path.module}/redirect-lambda/redirect.js.zip"
  source_file = "${path.module}/redirect-lambda/redirect.js"
}

resource "aws_iam_role_policy" "lambda_execution" {
  name_prefix = "lambda-execution-policy-"
  role        = aws_iam_role.lambda_execution.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:CreateLogGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda_execution" {
  name_prefix        = "lambda-execution-role-"
  description        = "Managed by Terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "edgelambda.amazonaws.com",
          "lambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  permissions_boundary = var.permissions_boundary
}

resource "aws_lambda_function" "redirect" {
  description      = "Managed by Terraform"
  filename         = "${path.module}/redirect-lambda/redirect.js.zip"
  function_name    = "redirect-${var.service_name}"
  handler          = "redirect.handler"
  source_code_hash = data.archive_file.redirect_zip.output_base64sha256
  provider         = aws.us-east-1
  publish          = true
  role             = aws_iam_role.lambda_execution.arn
  runtime          = "nodejs10.x"

}