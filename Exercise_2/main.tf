variable "lambda_function_name" {
  default = "udacity_lambda"
}

data "archive_file" "archive" {
  type        = "zip"
  source_file = "greet_lambda.py"
  output_path = "greet_lambda.zip"
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "udacity_lambda_function" {
  filename      = "greet_lambda.zip"
  function_name = var.lambda_function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "greet_lambda.lambda_handler"
  runtime       = "python3.8"
  environment {
    variables = {
      greeting = "Hello everyone!"
    }
  } 
 
  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.example,
  ]
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/udacity_lambda_function"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "demo_lambda_every_one_minute" {
  name = "demo_lambda_every_one_minute"
  depends_on = [
    "aws_lambda_function.udacity_lambda_function"
  ]
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "lambda_udacity" {
  target_id = "lambda_udacity" 
  rule = "${aws_cloudwatch_event_rule.demo_lambda_every_one_minute.name}"
  arn = "${aws_lambda_function.udacity_lambda_function.arn}"
}

resource "aws_lambda_permission" "demo_lambda_every_one_minute" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.udacity_lambda_function.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.demo_lambda_every_one_minute.arn}"
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}