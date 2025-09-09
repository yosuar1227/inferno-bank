terraform {
  required_providers {
    aws = {
      version = "~> 5.0",
      source  = "hashicorp/aws"
    }
  }
}

//Lets create the dynamo db table bank-user-table
resource "aws_dynamodb_table" "BankUserTable" {
  name           = "bank-user-table"
  billing_mode   = var.defaultBillingModeDynamoDb
  read_capacity  = 20
  write_capacity = 20
  hash_key       = var.hasKeyForBankUserTable
  range_key      = var.rangeKeyForBankUserTable
  attribute {
    name = var.hasKeyForBankUserTable
    type = "S"
  }
  attribute {
    name = var.rangeKeyForBankUserTable
    type = "S"
  }
  lifecycle {
    prevent_destroy = true
  }
}


//User service ----- register user lambda
resource "aws_lambda_function" "CreateRegisterUserLmb" {
  filename         = data.archive_file.registerUserLmb.output_path
  function_name    = var.registerUserLmbName //lambda name in aws console
  handler          = "${var.registerUserLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.roleForRegisterUserLmb.arn
  source_code_hash = data.archive_file.registerUserLmb.output_base64sha256

  environment {
    variables = {
      BankUserTable : aws_dynamodb_table.BankUserTable.arn
      secretBankName: aws_secretsmanager_secret.InfernoBankSecret.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachForRegisterUserLmb,
    data.archive_file.registerUserLmb
  ]
}

resource "aws_iam_role_policy" "policyForRegisterUserLmb" {
  name   = "lambdaRegisterUser"
  policy = data.aws_iam_policy_document.lambda_register_user_execution.json
  role   = aws_iam_role.roleForRegisterUserLmb.id
}

resource "aws_iam_role" "roleForRegisterUserLmb" {
  name               = "executionForRegisterUserLmb"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attachForRegisterUserLmb" {
  role       = aws_iam_role.roleForRegisterUserLmb.name
  policy_arn = var.defaultPolicyArn
}

//User service ----- register user api gateway
resource "aws_api_gateway_rest_api" "registerUserGtw" {
  name        = "registerUserRestApi"
  description = "rest api for register user"
}

resource "aws_api_gateway_resource" "registerUserGtwResource" {
  rest_api_id = aws_api_gateway_rest_api.registerUserGtw.id
  parent_id   = aws_api_gateway_rest_api.registerUserGtw.root_resource_id
  path_part   = "register"
}

resource "aws_api_gateway_method" "registerUserGtwMethod" {
  resource_id   = aws_api_gateway_resource.registerUserGtwResource.id
  rest_api_id   = aws_api_gateway_rest_api.registerUserGtw.id
  http_method   = var.HTTP_METHOD_POST
  authorization = var.NONE_AUTH
}
//Coneting register user lambda with register user gateway
resource "aws_api_gateway_integration" "lmbGtwIntegrationForRegisterUser" {
  rest_api_id             = aws_api_gateway_rest_api.registerUserGtw.id
  resource_id             = aws_api_gateway_resource.registerUserGtwResource.id
  http_method             = aws_api_gateway_method.registerUserGtwMethod.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.CreateRegisterUserLmb.invoke_arn
}
//give permissions
resource "aws_lambda_permission" "lmbGtwPermissionForRegisterUser" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.registerUserLmbName
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.registerUserGtw.execution_arn}/*/${var.HTTP_METHOD_POST}/${aws_api_gateway_resource.registerUserGtwResource.path_part}"
  depends_on = [
    aws_lambda_function.CreateRegisterUserLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "registerUserGtwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.registerUserGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwIntegrationForRegisterUser,
    aws_lambda_permission.lmbGtwPermissionForRegisterUser
  ]
}
//stage
resource "aws_api_gateway_stage" "registerUserGtwStage" {
  deployment_id = aws_api_gateway_deployment.registerUserGtwDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.registerUserGtw.id
  stage_name    = var.STAGE
}
//url
output "registerUserGtwUrl" {
  value = "${aws_api_gateway_stage.registerUserGtwStage.invoke_url}/${aws_api_gateway_resource.registerUserGtwResource.path_part}"
}

//adding secret manager
resource "aws_secretsmanager_secret" "InfernoBankSecret" {
  name        = "InfernoBankSecret"
  description = "I am in hell and even in hell I keep a secret"
}

resource "aws_secretsmanager_secret_version" "InfernoBankSecretVersion" {
  secret_id = aws_secretsmanager_secret.InfernoBankSecret.id
  secret_string = jsonencode({
    key : "$2a$12$tony0OEk29LEXpBoq0gFb.aYpmhOY9b3nR9rb8.kStD0whofFk/Iq"
  })
}

