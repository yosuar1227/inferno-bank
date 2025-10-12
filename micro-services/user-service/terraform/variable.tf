
variable "defaultRunTime" {
  type = string
  default = "nodejs20.x"
  description = "default run time for this project"
}

variable "defaultPolicyArn" {
  type = string
  default = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  description = "default policy arn for this project and lambdas"
}

variable "defaultBillingModeDynamoDb" {
  type = string
  default = "PROVISIONED"
  description = "default billing mode value for dynamo db"
}

variable "hasKeyForBankUserTable" {
  type = string
  default = "uuid"
}

variable "rangeKeyForBankUserTable" {
  type = string
  default = "document"
}

variable "emailKey" {
  type = string
  default = "email"
}

variable "SECONDARY_EMAIL_INDEX" {
  type = string
  default = "email-index"
}

variable "STAGE" {
  type = string
  default = "dev"
}

variable "NONE_AUTH" {
  type = string
  default = "NONE"
}

variable "AWS_PROXY" {
  type = string
  default = "AWS_PROXY"
}

variable "HTTP_METHOD_POST" {
  type = string
  default = "POST"
}

variable "HTTP_METHOD_PUT" {
  type = string
  default = "PUT"
}

variable "HTTP_METHOD_GET" {
  type = string
  default = "GET"
}

variable "AMAZON_API_COM" {
  type = string
  default = "apigateway.amazonaws.com"
  description = "principal url for apigateway"
}

//lambdas de user service
variable "registerUserLmbName" {
  type = string
  default = "register-user-lambda"
  description = "variable just for the name of the register user lambda in user service"
}

variable "loginUserLmbName" {
  type = string
  default = "login-user-lambda"
  description = "variable just for the name of the login user lambda in user service"
}

variable "updateProfileLmbName" {
  type = string
  default = "update-profile-lambda"
  description = "variable just fopr the name of the update profile user lambda in user service"
}

variable "addUserAvatarLmbName" {
  type = string
  default= "add-user-avatar"
  description = "variable just for the name of the add avatar for users lambda in user service"
}

variable "getUserProfileLmbName" {
  type = string
  default = "get-user-profile"
  description = "variable just for the name of the get user profile lambda in user service"
}

//aws s3 bucket name
variable "s3_files_variable_storage" {
  type = string
  default = "files-bucket-storage-yosuar-mieles"
}