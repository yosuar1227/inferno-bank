data "aws_availability_zones" "available" {
  state = "available"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../app/dist/handlers/getData.js"
  output_path = "${path.module}/${var.lambda_zip_path}"
}

data "archive_file" "getCatalogDataLmb" {
  type        = "zip"
  source_file = "${path.module}/../app/dist/handlers/${var.lambda_get_catalog_data}.js"
  output_path = "${path.module}/lambda_get_catalog_data.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}


data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambdaGetCatalogExecution" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface"
    ]
    resources = ["*"]
  }
}

