data "archive_file" "createRequestCardLmb" {
  type        = "zip"
  source_file = "${path.module}./app/dist/${var.createRequestCardLmbName}.js"
  output_path = "${path.module}/files/lambda_create_request_card_sqs_proccesor.zip"
}


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

data "aws_iam_policy_document" "lambdaCreateRequestCardExecution" {
  statement {
    effect = "Allow"
    actions = [
      //estos 3 siempre deben estar para evitar problemas
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [
      aws_sqs_queue.createCardSqs.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.BankCardTable.arn
    ]
  }

}
