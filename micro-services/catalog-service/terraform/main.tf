// configuracion del cluster
// necesitamos tablas de enrutamiento en AWS -> Redes de computadora
// VPC enpoints -> redes virtuales a nivel de cloud
//subneting (private y public)

//VPC endpoint
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

//Internet Gateway -> puerta de enlace
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

//Public Subnet
resource "aws_subnet" "public" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
}

//Private Subnet (for redis and lambda related)
//redis AWS -> No es publica -> Aunque tenga la URL no se puede conectar
resource "aws_subnet" "private" {
  count      = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  //zonas de disponibilidad
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

//Tablas de enrutamiento -> Route table for public subnests
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"                  //permitir que cualquier persona pueda acceder a esa tabla
    gateway_id = aws_internet_gateway.main.id //permite la salida a internet desde AWS
  }
}

//Route table for private subnests
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

//Route table association for public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

//Route table association for private subnests
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

//Cluster redis
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = var.redis_cluster_name
  engine               = "redis"
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_nodes
  parameter_group_name = "default.redis7"
  port                 = 6379
  security_group_ids   = [aws_security_group.redis_sg.id]
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.id
}

//subnet for redis
resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "${var.redis_cluster_name}-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.redis_cluster_name}-sg"
  description = "Security group for redis cluster"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "redis for lambda"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [
      aws_security_group.lambda_sg.id,
      aws_security_group.getCatalogDataLmbSg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "${var.lambda_function_name}-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.lambda_function_name}-sg"
  description = "Security group for lambda function"
  vpc_id      = aws_vpc.main.id

  // no se recibe nada en la lambda, la lambda debe hacer una peticion
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lambda_function" "redis_lambda" {
  filename         = var.lambda_zip_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "dist/getData.handler"
  runtime          = var.defaultLmbRunTime
  timeout          = 30
  memory_size      = 256
  source_code_hash = data.archive_file.lambda.output_base64sha256


  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      REDIS_ENDPOINT = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
      REDIS_PORT     = aws_elasticache_cluster.redis_cluster.port
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    data.archive_file.lambda,
    aws_elasticache_cluster.redis_cluster
  ]
}

//START -> LAMBDA GET CATALOG DATA
resource "aws_lambda_function" "getCatalogDataLmb" {
  filename         = data.archive_file.getCatalogDataLmb.output_path
  function_name    = var.lambda_get_catalog_data
  handler          = "dist/${var.lambda_get_catalog_data}.handler"
  runtime          = var.defaultLmbRunTime
  timeout          = 30
  memory_size      = 256
  role             = aws_iam_role.roleGetCatalogDataLmb.arn
  source_code_hash = data.archive_file.getCatalogDataLmb.output_base64sha256

  vpc_config {
    subnet_ids = aws_subnet.private[*].id
    security_group_ids = [
      aws_security_group.getCatalogDataLmbSg.id
    ]
  }

  environment {
    variables = {
      REDIS_ENDPOINT = aws_elasticache_cluster.redis_cluster.cache_nodes[0].address
      REDIS_PORT     = aws_elasticache_cluster.redis_cluster.port
    }
  }

  depends_on = [
    aws_iam_role_policy.policyGetCatalogDataLmb,
    data.archive_file.getCatalogDataLmb,
    aws_elasticache_cluster.redis_cluster
  ]
}
//policy
resource "aws_iam_role_policy" "policyGetCatalogDataLmb" {
  name   = "lambdaGetCatalogData-policy"
  policy = data.aws_iam_policy_document.lambdaGetCatalogExecution.json
  role   = aws_iam_role.roleGetCatalogDataLmb.id
}
//role
resource "aws_iam_role" "roleGetCatalogDataLmb" {
  name               = "executionForGetCatalogDataLmb-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//security group for lambda
resource "aws_security_group" "getCatalogDataLmbSg" {
  name        = "lambdaGetCatalogData-sg"
  description = "Security group for lambda get catalog data"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
//END LAMBDA
//START API GATEWAY FOT THE LAMBDA
resource "aws_api_gateway_rest_api" "getCatalogdataGtw" {
  name        = "getCatalogDataRestApi"
  description = "rest api fot the get catalof data"
}
//resource root path
resource "aws_api_gateway_resource" "getCatalogDataRoot" {
  rest_api_id = aws_api_gateway_rest_api.getCatalogdataGtw.id
  parent_id   = aws_api_gateway_rest_api.getCatalogdataGtw.root_resource_id
  path_part   = "catalog"
}
//gtw method
resource "aws_api_gateway_method" "getCatalogDataMethodGtw" {
  rest_api_id   = aws_api_gateway_rest_api.getCatalogdataGtw.id
  resource_id   = aws_api_gateway_resource.getCatalogDataRoot.id
  http_method   = var.HTTP_METHOD_GET
  authorization = var.NONE_AUTH
}
//connect lambda with gateway
resource "aws_api_gateway_integration" "lmbGtwGetCatalogDataIntegration" {
  rest_api_id             = aws_api_gateway_rest_api.getCatalogdataGtw.id
  resource_id             = aws_api_gateway_resource.getCatalogDataRoot.id
  http_method             = aws_api_gateway_method.getCatalogDataMethodGtw.http_method
  integration_http_method = var.HTTP_METHOD_POST
  type                    = var.AWS_PROXY
  uri                     = aws_lambda_function.getCatalogDataLmb.invoke_arn
}
//permissions
resource "aws_lambda_permission" "getCatalogDataGtwPermission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_get_catalog_data
  principal     = var.AMAZON_API_COM
  source_arn    = "${aws_api_gateway_rest_api.getCatalogdataGtw.execution_arn}/*/${var.HTTP_METHOD_GET}/${aws_api_gateway_resource.getCatalogDataRoot.path_part}"
  depends_on = [
    aws_lambda_function.getCatalogDataLmb
  ]
}
//deploy
resource "aws_api_gateway_deployment" "getCatalogDataDeploy" {
  rest_api_id = aws_api_gateway_rest_api.getCatalogdataGtw.id
  depends_on = [
    aws_api_gateway_integration.lmbGtwGetCatalogDataIntegration,
    aws_lambda_permission.getCatalogDataGtwPermission
  ]
}
//stage
resource "aws_api_gateway_stage" "getCatalogDataStage" {
  deployment_id = aws_api_gateway_deployment.getCatalogDataDeploy.id
  rest_api_id   = aws_api_gateway_rest_api.getCatalogdataGtw.id
  stage_name    = var.STAGE
}
//url
output "getCatalogDataGtwUrl" {
  value = "${aws_api_gateway_stage.getCatalogDataStage.invoke_url}/${aws_api_gateway_resource.getCatalogDataRoot.path_part}"
}
//END GATEWAY
