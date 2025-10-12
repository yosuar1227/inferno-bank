//main tf for card service
//DLQ FOR THE NEXT SQS
resource "aws_sqs_queue" "dlqCreateCardSqs" {
  name = var.createCardSqsDlq
}

//CREATE CARDS SQS - create-request-card-sqs
resource "aws_sqs_queue" "createCardSqs" {
  name                        = var.createCardSqs
  fifo_queue                  = false
  content_based_deduplication = false
  visibility_timeout_seconds  = var.DEFAUL_VISIBILITY_TIMEOUT
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlqCreateCardSqs.arn
    maxReceiveCount     = var.DEFAULT_MAX_RECEIVE_COUNT
  })
}
//START LAMBDA = create-request-card-lambda
resource "aws_lambda_function" "createRequestCardLmb" {
  filename         = data.archive_file.createRequestCardLmb.output_path
  function_name    = var.createRequestCardLmbName
  handler          = "${var.createRequestCardLmbName}.handler"
  runtime          = var.defaultRunTime
  timeout          = 900
  memory_size      = 256
  role             = aws_iam_role.createRequestCardRole.arn
  source_code_hash = data.archive_file.createRequestCardLmb.output_base64sha256
  publish = true

  depends_on = [
    aws_iam_role_policy_attachment.createRequestCardAttach,
    data.archive_file.createRequestCardLmb,
    aws_sqs_queue.createCardSqs,
    aws_sqs_queue.dlqCreateCardSqs
  ]
}
//policy
resource "aws_iam_role_policy" "createRequestCardPolicy" {
  name   = "lambdaCreateRequestCard"
  policy = data.aws_iam_policy_document.lambdaCreateRequestCardExecution.json
  role   = aws_iam_role.createRequestCardRole.id
}
//role
resource "aws_iam_role" "createRequestCardRole" {
  name               = "executionForCreateRequestCard"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
//attachment
resource "aws_iam_role_policy_attachment" "createRequestCardAttach" {
  role       = aws_iam_role.createRequestCardRole.name
  policy_arn = var.defaultPolicyArn
}
//END OF LAMBDA CONF
//CONFIG LAMBDA AND RELATE TO THE SQS
resource "aws_lambda_event_source_mapping" "executeLmbSqsCreateRequestCard" {
  event_source_arn                   = aws_sqs_queue.createCardSqs.arn
  function_name                      = aws_lambda_function.createRequestCardLmb.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 0
  enabled                            = true
  function_response_types            = ["ReportBatchItemFailures"]
  scaling_config {
    maximum_concurrency = 5
  }
}
//END OF CONFIG