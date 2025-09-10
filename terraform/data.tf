//user service
//register user archive file
data "archive_file" "registerUserLmb" {
  type        = "zip"
  source_file = "${path.module}./micro-services/user-service/dist/${var.registerUserLmbName}.js"
  output_path = "lambda_register_user.zip"
}

data "archive_file" "loginUserLmb" {
  type        = "zip"
  source_file = "${path.module}./micro-services/user-service/dist/${var.loginUserLmbName}.js"
  output_path = "lambda_login_user.zip"
}

data "archive_file" "updateProfileLmb" {
  type        = "zip"
  source_file = "${path.module}./micro-services/user-service/dist/${var.updateProfileLmbName}.js"
  output_path = "lambda_update_user_profile.zip"
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

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.InfernoBankSecret.arn]
  }
}

data "aws_iam_policy_document" "lambdaLoginUserExecution" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [
      aws_dynamodb_table.BankUserTable.arn,
      "${aws_dynamodb_table.BankUserTable.arn}/index/${var.SECONDARY_EMAIL_INDEX}"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.InfernoBankSecret.arn]
  }
}

data "aws_iam_policy_document" "lambdaUpdateUserProfileExecution" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.BankUserTable.arn]
  }
}

//config for yosuar
/*data "aws_iam_policy_document" "lambdaUpdateUserProfileExecution" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem"
    ]
    resources = ["*"]
  }
}*/
