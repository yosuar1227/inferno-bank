//USER SERVICE LAMBDAS
//register user archive file
data "archive_file" "registerUserLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.registerUserLmbName}.js"
  output_path = "${path.module}/files/lambda_register_user.zip"
}

data "archive_file" "loginUserLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.loginUserLmbName}.js"
  output_path = "${path.module}/files/lambda_login_user.zip"
}

data "archive_file" "updateProfileLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.updateProfileLmbName}.js"
  output_path = "${path.module}/files/lambda_update_user_profile.zip"
}

data "archive_file" "addUserAvatarLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.addUserAvatarLmbName}.js"
  output_path = "${path.module}/files/lambda_add_user_avatar.zip"
}

data "archive_file" "getUserProfileLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.getUserProfileLmbName}.js"
  output_path = "${path.module}/files/lambda_get_user_profile.zip"
}
//END OF USER SERVICE
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

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.InfernoBankSecret.arn]
  }
}

data "aws_iam_policy_document" "lambdaAddUserAvatarExecution" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.InfernoBankSecret.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.UserServiceS3Bucket.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.BankUserTable.arn]
  }
}

data "aws_iam_policy_document" "lambdaGetUserProfile" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.BankUserTable.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.UserServiceS3Bucket.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.InfernoBankSecret.arn]
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
