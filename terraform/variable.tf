
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

variable "registerUserLmbName" {
  type = string
  default = "register-user-lambda"
  description = "variable just for the name of the register user lambda in user service"
}