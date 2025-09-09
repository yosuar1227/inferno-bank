//test archive file
data "archive_file" "registerUserLmb" {
  type        = "zip"
  source_file = "${path.module}./micro-services/user-service/dist/${var.registerUserLmbName}.js"
  output_path = "lambda_register_user.zip"
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

//for test easy lambda use this, also I do not if I will use this policy for all lambdas
data "aws_iam_policy_document" "lambda_register_user_execution" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.BankUserTable.arn
    ]
  }
}
