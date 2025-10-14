variable "HTTP_METHOD_GET" {
  type    = string
  default = "GET"
}

variable "HTTP_METHOD_POST" {
  type    = string
  default = "POST"
}

variable "NONE_AUTH" {
  type    = string
  default = "NONE"
}

variable "AWS_PROXY" {
  type    = string
  default = "AWS_PROXY"
}

variable "STAGE" {
  type    = string
  default = "dev"
}

variable "AMAZON_API_COM" {
  type        = string
  default     = "apigateway.amazonaws.com"
  description = "principal url for apigateway"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr block for vpc"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "redis_cluster_name" {
  type    = string
  default = "redis-cluster"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro" //instance
}

variable "redis_num_nodes" {
  type    = number
  default = 1
}

variable "lambda_zip_path" {
  type    = string
  default = "lambda.zip"
}

variable "defaultLmbRunTime" {
  type    = string
  default = "nodejs20.x"
}

variable "lambda_function_name" {
  type    = string
  default = "getUserLambda"
}

variable "lambda_get_catalog_data" {
  type    = string
  default = "get-catalog-data"
}
