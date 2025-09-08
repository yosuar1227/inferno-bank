terraform {
  required_providers {
    aws = {
      version = "~> 5.0",
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_lambda_function" "TestEventLmb" {
  filename         = "testevent.zip"
  function_name    = "testEventLambda"
  handler          = "test.handler"
  runtime          = "nodejs20.x"
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.lambda_user_create_file.output_base64sha256
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    data.archive_file.lambda_user_create_file
  ]
}

resource "aws_iam_role_policy" "im_policy_for_lambda" {
  name   = "lambdaTestEvent"
  policy = data.aws_iam_policy_document.lambda_execution.json
  role   = aws_iam_role.iam_for_lambda.id
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "ExecutionTestLambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
