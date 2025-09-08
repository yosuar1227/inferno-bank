//test archive file
data "archive_file" "lambda_user_create_file" {
  type        = "zip"
  source_file = "${path.module}./micro-services/card-service/dist/test.js"
  output_path = "testevent.zip"
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

//for test easy lambda use this
data "aws_iam_policy_document" "lambda_execution" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem"
    ]
    resources = ["*"]
  }
}
