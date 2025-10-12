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
  //email attribute for email-index
  attribute {
    name = var.emailKey
    type = "S"
  }

  global_secondary_index {
    name            = var.SECONDARY_EMAIL_INDEX
    hash_key        = var.emailKey
    projection_type = "ALL"
    read_capacity   = 10
    write_capacity  = 10
  }

  lifecycle {
    prevent_destroy = true
  }
}

//adding secret manager
resource "aws_secretsmanager_secret" "InfernoBankSecret" {
  name        = "InfernoBankSecretV2"
  description = "I am in hell and even in hell I keep a secret"
}

resource "aws_secretsmanager_secret_version" "InfernoBankSecretVersion" {
  secret_id = aws_secretsmanager_secret.InfernoBankSecret.id
  secret_string = jsonencode({
    key : "$2a$12$tony0OEk29LEXpBoq0gFb.aYpmhOY9b3nR9rb8.kStD0whofFk/Iq"
  })
}

//adding S3 service
resource "aws_s3_bucket" "UserServiceS3Bucket" {
  bucket = var.s3_files_variable_storage
}

resource "aws_iam_policy" "UserServiceS3WriteAccess" {
  name        = "USS3WriteAccessToBucket"
  description = "this policy is only for write access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow"
        Action : [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.UserServiceS3Bucket.arn}/*"
      }
    ]
  })
}

//User service ----- REGISTER USER LAMNBDA
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
      secretBankName : aws_secretsmanager_secret.InfernoBankSecret.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachForRegisterUserLmb,
    data.archive_file.registerUserLmb
  ]
}
//policy
resource "aws_iam_role_policy" "policyForRegisterUserLmb" {
  name   = "lambdaRegisterUser"
  policy = data.aws_iam_policy_document.lambda_register_user_execution.json
  role   = aws_iam_role.roleForRegisterUserLmb.id
}
//role
resource "aws_iam_role" "roleForRegisterUserLmb" {
  name               = "executionForRegisterUserLmb"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//attachment
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
//config to add more path, for dynamic path use {value}
//for other path just create another resource and use the parent id of the previous route
resource "aws_api_gateway_method" "registerUserGtwMethod" {
  rest_api_id   = aws_api_gateway_rest_api.registerUserGtw.id
  resource_id   = aws_api_gateway_resource.registerUserGtwResource.id
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
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.registerUserGtw.execution_arn}/*/${var.HTTP_METHOD_POST}/${aws_api_gateway_resource.registerUserGtwResource.path_part}"
  depends_on = [
    aws_lambda_function.CreateRegisterUserLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "registerUserGtwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.registerUserGtw.id

  /*triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.registerUserGtwResource.id,
      aws_api_gateway_method.registerUserGtwMethod.id,
      aws_api_gateway_integration.lmbGtwIntegrationForRegisterUser.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }*/

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


//User service ----- LOGIN USER LAMBDA
resource "aws_lambda_function" "LoginUserLmb" {
  filename         = data.archive_file.loginUserLmb.output_path
  function_name    = var.loginUserLmbName
  handler          = "${var.loginUserLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.roleForLoginUserLmb.arn
  source_code_hash = data.archive_file.loginUserLmb.output_base64sha256

  environment {
    variables = {
      BankUserTable : aws_dynamodb_table.BankUserTable.arn
      secretBankName : aws_secretsmanager_secret.InfernoBankSecret.name
      BankEmailIndex : var.SECONDARY_EMAIL_INDEX
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachForLoginUserLmb,
    data.archive_file.loginUserLmb
  ]
}

resource "aws_iam_role_policy" "policyForLoginUserLmb" {
  name   = "lambdaPolicyLoginUser"
  policy = data.aws_iam_policy_document.lambdaLoginUserExecution.json
  role   = aws_iam_role.roleForLoginUserLmb.id
}

resource "aws_iam_role" "roleForLoginUserLmb" {
  name               = "executionForLoginUserLmb"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "attachForLoginUserLmb" {
  role       = aws_iam_role.roleForLoginUserLmb.name
  policy_arn = var.defaultPolicyArn
}
//User service ----- login user api gateway
resource "aws_api_gateway_rest_api" "loginUserGtw" {
  name        = "loginUserRestApi"
  description = "rest api for login user"
}
//resource gateway
resource "aws_api_gateway_resource" "loginUserRoot" {
  rest_api_id = aws_api_gateway_rest_api.loginUserGtw.id
  parent_id   = aws_api_gateway_rest_api.loginUserGtw.root_resource_id
  path_part   = "login"
}
//gtw method
resource "aws_api_gateway_method" "loginUserGtwMethod" {
  rest_api_id   = aws_api_gateway_rest_api.loginUserGtw.id
  resource_id   = aws_api_gateway_resource.loginUserRoot.id
  http_method   = var.HTTP_METHOD_POST
  authorization = var.NONE_AUTH
}
//conecting login user lambda with the gateway
resource "aws_api_gateway_integration" "lmbGtwLoginUserIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.loginUserGtw.id
  resource_id             = aws_api_gateway_resource.loginUserRoot.id
  http_method             = aws_api_gateway_method.loginUserGtwMethod.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.LoginUserLmb.invoke_arn
}
//permissions
resource "aws_lambda_permission" "lmbGtwLoginUserPermission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.loginUserLmbName
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.loginUserGtw.execution_arn}/*/${var.HTTP_METHOD_POST}/${aws_api_gateway_resource.loginUserRoot.path_part}"
  depends_on = [
    aws_lambda_function.LoginUserLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "loginUserGtwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.loginUserGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwLoginUserIntegration,
    aws_lambda_permission.lmbGtwLoginUserPermission
  ]
}
//stage
resource "aws_api_gateway_stage" "loginUserGtwStage" {
  deployment_id = aws_api_gateway_deployment.loginUserGtwDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.loginUserGtw.id
  stage_name    = var.STAGE
}
//url
output "loginUserGtwUrl" {
  value = "${aws_api_gateway_stage.loginUserGtwStage.invoke_url}/${aws_api_gateway_resource.loginUserRoot.path_part}"
}

//User service -> UPDATE PROFILE USER LAMBDA
resource "aws_lambda_function" "UpdateUserProfileLmb" {
  filename         = data.archive_file.updateProfileLmb.output_path
  function_name    = var.updateProfileLmbName
  handler          = "${var.updateProfileLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.UpdateUserProfileRole.arn
  source_code_hash = data.archive_file.updateProfileLmb.output_base64sha256

  environment {
    variables = {
      BankUserTable : aws_dynamodb_table.BankUserTable.arn
      secretBankName : aws_secretsmanager_secret.InfernoBankSecret.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachUpdateUserProfile,
    data.archive_file.updateProfileLmb
  ]
}
//policy
resource "aws_iam_role_policy" "UpdateUserProfilePolicy" {
  name   = "lambdaUpdateUserProfile"
  policy = data.aws_iam_policy_document.lambdaUpdateUserProfileExecution.json
  role   = aws_iam_role.UpdateUserProfileRole.id
}
//role
resource "aws_iam_role" "UpdateUserProfileRole" {
  name               = "executionForUpdateUserProfile"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//attachment
resource "aws_iam_role_policy_attachment" "attachUpdateUserProfile" {
  role       = aws_iam_role.UpdateUserProfileRole.name
  policy_arn = var.defaultPolicyArn
}
/*****User service ----- update user profile api gateway*****/
resource "aws_api_gateway_rest_api" "updateUserProfileGtw" {
  name        = "updateUserProfileRestApi"
  description = "rest api for update user profile"
}
//resource gateway -> profile path
resource "aws_api_gateway_resource" "updateUserProfileRoot" {
  rest_api_id = aws_api_gateway_rest_api.updateUserProfileGtw.id
  parent_id   = aws_api_gateway_rest_api.updateUserProfileGtw.root_resource_id
  path_part   = "profile"
}
//resource gateway -> {user_id} path
resource "aws_api_gateway_resource" "updateUserProfileUserId" {
  rest_api_id = aws_api_gateway_rest_api.updateUserProfileGtw.id
  parent_id   = aws_api_gateway_resource.updateUserProfileRoot.id
  path_part   = "{user_id}"
}
//gtw method
resource "aws_api_gateway_method" "updateUserProfileMethodGtw" {
  rest_api_id   = aws_api_gateway_rest_api.updateUserProfileGtw.id
  resource_id   = aws_api_gateway_resource.updateUserProfileUserId.id
  http_method   = var.HTTP_METHOD_PUT
  authorization = var.NONE_AUTH
}
//conecting update user profile lambda with the gateway
resource "aws_api_gateway_integration" "lmbGtwUpdateUserProfileIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.updateUserProfileGtw.id
  resource_id             = aws_api_gateway_resource.updateUserProfileUserId.id
  http_method             = aws_api_gateway_method.updateUserProfileMethodGtw.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.UpdateUserProfileLmb.invoke_arn
}
//permissions
resource "aws_lambda_permission" "updateUserProfileGtwPermission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.updateProfileLmbName
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.updateUserProfileGtw.execution_arn}/*/${var.HTTP_METHOD_PUT}/${aws_api_gateway_resource.updateUserProfileRoot.path_part}/${aws_api_gateway_resource.updateUserProfileUserId.path_part}"
  depends_on = [
    aws_lambda_function.UpdateUserProfileLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "updateUserProfileGtwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.updateUserProfileGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwUpdateUserProfileIntegration,
    aws_lambda_permission.updateUserProfileGtwPermission
  ]
}
//stage
resource "aws_api_gateway_stage" "updateUserProfileStage" {
  deployment_id = aws_api_gateway_deployment.updateUserProfileGtwDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.updateUserProfileGtw.id
  stage_name    = var.STAGE
}
//url
output "updateUserProfileGtwUrl" {
  value = "${aws_api_gateway_stage.updateUserProfileStage.invoke_url}/${aws_api_gateway_resource.updateUserProfileRoot.path_part}/${aws_api_gateway_resource.updateUserProfileUserId.path_part}"
}
//USER SERVICE -> ADD USER AVATAR LAMBDA
resource "aws_lambda_function" "addUserAvatarLmb" {
  filename         = data.archive_file.addUserAvatarLmb.output_path
  function_name    = var.addUserAvatarLmbName
  handler          = "${var.addUserAvatarLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.addUserAvatarRole.arn
  source_code_hash = data.archive_file.addUserAvatarLmb.output_base64sha256

  environment {
    variables = {
      secretBankName : aws_secretsmanager_secret.InfernoBankSecret.name
      fileBucket : aws_s3_bucket.UserServiceS3Bucket.bucket
      BankUserTable : aws_dynamodb_table.BankUserTable.arn
    }
  }


  depends_on = [
    aws_iam_role_policy_attachment.attachAddUserAvatar,
    data.archive_file.addUserAvatarLmb
  ]
}
//policy
resource "aws_iam_role_policy" "addUserAvatarPolicy" {
  name   = "lambdaAddUserAvatar"
  policy = data.aws_iam_policy_document.lambdaAddUserAvatarExecution.json
  role   = aws_iam_role.addUserAvatarRole.id
}
//role
resource "aws_iam_role" "addUserAvatarRole" {
  name               = "executionForAddUserAvatar"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//attachment
resource "aws_iam_role_policy_attachment" "attachAddUserAvatar" {
  role       = aws_iam_role.addUserAvatarRole.name
  policy_arn = var.defaultPolicyArn
}
//END OF ADD USER AVATAR LAMBDA
//START UPLOAD USER AVATAR GATEWAY
resource "aws_api_gateway_rest_api" "uploadUserAvatarGtw" {
  name        = "uploadUserAvatarRestApi"
  description = "rest api for upload user avatar"
}
//resource gateway
resource "aws_api_gateway_resource" "uploadUserAvatarRoot" {
  rest_api_id = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  parent_id   = aws_api_gateway_rest_api.uploadUserAvatarGtw.root_resource_id
  path_part   = "profile"
}
//resource gateway -> {user_id} path
resource "aws_api_gateway_resource" "uploadUserAvatarUserId" {
  rest_api_id = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  parent_id   = aws_api_gateway_resource.uploadUserAvatarRoot.id
  path_part   = "{user_id}"
}
//resource gateway -> avatar path
resource "aws_api_gateway_resource" "uploadUserAvatarPathAvatar" {
  rest_api_id = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  parent_id   = aws_api_gateway_resource.uploadUserAvatarUserId.id
  path_part   = "avatar"
}
//gtw method
resource "aws_api_gateway_method" "uploadUserAvatarMethodGtw" {
  rest_api_id   = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  resource_id   = aws_api_gateway_resource.uploadUserAvatarPathAvatar.id
  http_method   = var.HTTP_METHOD_POST
  authorization = var.NONE_AUTH
}
//conecting update user profile lambda with the gateway
resource "aws_api_gateway_integration" "lmbGtwUploadUserAvatarIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  resource_id             = aws_api_gateway_resource.uploadUserAvatarPathAvatar.id
  http_method             = aws_api_gateway_method.uploadUserAvatarMethodGtw.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.addUserAvatarLmb.invoke_arn
}
//permissions
resource "aws_lambda_permission" "uploadUserAvatarGtwPermissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.addUserAvatarLmbName
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.uploadUserAvatarGtw.execution_arn}/*/${var.HTTP_METHOD_POST}/${aws_api_gateway_resource.uploadUserAvatarRoot.path_part}/${aws_api_gateway_resource.uploadUserAvatarUserId.path_part}/${aws_api_gateway_resource.uploadUserAvatarPathAvatar.path_part}"
  depends_on = [
    aws_lambda_function.addUserAvatarLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "uploadUserAvatarGtwDeploy" {
  rest_api_id = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwUploadUserAvatarIntegration,
    aws_lambda_permission.uploadUserAvatarGtwPermissions
  ]
}
//stage
resource "aws_api_gateway_stage" "uploadUserAvatarStage" {
  deployment_id = aws_api_gateway_deployment.uploadUserAvatarGtwDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.uploadUserAvatarGtw.id
  stage_name    = var.STAGE
}
//url
output "uploadUserAvatarGtwUrl" {
  value = "${aws_api_gateway_stage.uploadUserAvatarStage.invoke_url}/${aws_api_gateway_resource.uploadUserAvatarRoot.path_part}/${aws_api_gateway_resource.uploadUserAvatarUserId.path_part}/${aws_api_gateway_resource.uploadUserAvatarPathAvatar.path_part}"
}
//END UPLOAD USER AVATAR GTW
//START GET USER PROFLE LAMBDA
resource "aws_lambda_function" "getUserProfileLmb" {
  filename         = data.archive_file.getUserProfileLmb.output_path
  function_name    = var.getUserProfileLmbName
  handler          = "${var.getUserProfileLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.getUserProfileRole.arn
  source_code_hash = data.archive_file.getUserProfileLmb.output_base64sha256

  environment {
    variables = {
      fileBucket : aws_s3_bucket.UserServiceS3Bucket.bucket
      BankUserTable : aws_dynamodb_table.BankUserTable.arn
      secretBankName : aws_secretsmanager_secret.InfernoBankSecret.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.attachGetUserProfile,
    data.archive_file.getUserProfileLmb
  ]
}
//policy
resource "aws_iam_role_policy" "getUserProfilePolicy" {
  name   = "lambdaGetUserProfile"
  policy = data.aws_iam_policy_document.lambdaGetUserProfile.json
  role   = aws_iam_role.getUserProfileRole.id
}
//role
resource "aws_iam_role" "getUserProfileRole" {
  name               = "executionGetUserProfile"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//attachment
resource "aws_iam_role_policy_attachment" "attachGetUserProfile" {
  role       = aws_iam_role.getUserProfileRole.name
  policy_arn = var.defaultPolicyArn
}
//END OF GET USER PROFILE LAMBDA
//START WITH GATEWAY
resource "aws_api_gateway_rest_api" "getUserProfileGtw" {
  name        = "getUserProfileRestApi"
  description = "rest api to get the user profile data"
}
//resource
resource "aws_api_gateway_resource" "getUserProfileRoot" {
  rest_api_id = aws_api_gateway_rest_api.getUserProfileGtw.id
  parent_id   = aws_api_gateway_rest_api.getUserProfileGtw.root_resource_id
  path_part   = "profile"
}
//resource -> {user_id} path
resource "aws_api_gateway_resource" "getUserProfileUserId" {
  rest_api_id = aws_api_gateway_rest_api.getUserProfileGtw.id
  parent_id   = aws_api_gateway_resource.getUserProfileRoot.id
  path_part   = "{user_id}"
}
//method
resource "aws_api_gateway_method" "getUserProfileMethodGtw" {
  rest_api_id   = aws_api_gateway_rest_api.getUserProfileGtw.id
  resource_id   = aws_api_gateway_resource.getUserProfileUserId.id
  http_method   = var.HTTP_METHOD_GET
  authorization = var.NONE_AUTH
}
//conecting get user profile lambda with the gateway
resource "aws_api_gateway_integration" "lmbGtwGetUserProfileIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.getUserProfileGtw.id
  resource_id             = aws_api_gateway_resource.getUserProfileUserId.id
  http_method             = aws_api_gateway_method.getUserProfileMethodGtw.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.getUserProfileLmb.invoke_arn
}
//permissions
resource "aws_lambda_permission" "getUserProfileGtwPermissions" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.getUserProfileLmbName
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.getUserProfileGtw.execution_arn}/*/${var.HTTP_METHOD_GET}/${aws_api_gateway_resource.getUserProfileRoot.path_part}/${aws_api_gateway_resource.getUserProfileUserId.path_part}"
  depends_on = [
    aws_lambda_function.getUserProfileLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "getUserProfileDeploy" {
  rest_api_id = aws_api_gateway_rest_api.getUserProfileGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwGetUserProfileIntegration,
    aws_lambda_permission.getUserProfileGtwPermissions
  ]
}
//stage
resource "aws_api_gateway_stage" "getUserProfileStage" {
  deployment_id = aws_api_gateway_deployment.getUserProfileDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.getUserProfileGtw.id
  stage_name    = var.STAGE
}
//url
output "getUserProfileGtwUrl" {
  value = "${aws_api_gateway_stage.getUserProfileStage.invoke_url}/${aws_api_gateway_resource.getUserProfileRoot.path_part}/${aws_api_gateway_resource.getUserProfileUserId.path_part}"
}
//END GATEWAY
