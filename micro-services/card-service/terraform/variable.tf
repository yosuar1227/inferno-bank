//SQS - create-request-card-sqs
variable "createCardSqs" {
  type = string
  default = "create-card-sqs"
}

variable "createCardSqsDlq" {
  type = string
  default = "create-card-sqs-dlq"
}

variable "DEFAUL_VISIBILITY_TIMEOUT" {
  type = number
  default = 900 //in seconds
}

variable "DEFAULT_MAX_RECEIVE_COUNT" {
  type = number
  default = 5
}

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

//lambda names
variable "createRequestCardLmbName" {
  type = string
  default = "request-card-sqs-proccesor"
  description = "variable just fot the name of the create request card lambnda in card service"
}