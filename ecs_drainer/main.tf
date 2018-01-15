resource "aws_sns_topic" "default" {
  name = "asg-drainer"
}

resource "aws_sns_topic_subscription" "default" {
  topic_arn = "${aws_sns_topic.default.arn}"
  endpoint  = "${aws_lambda_function.default.arn}"
  protocol  = "lambda"
}

resource "aws_lambda_function" "default" {
  function_name    = "drainer"
  handler          = "index.lambda_handler"
  role             = "${aws_iam_role.asg_lambda.arn}"
  runtime          = "python2.7"
  filename         = "${path.module}/index.zip"
  source_code_hash = "${base64sha256(file("${path.module}/index.zip"))}"
  timeout          = 300
  memory_size      = 128

  environment {
    variables {
      CLUSTER_NAME = "${var.cluster_name}"
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.default.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.default.arn}"
}

resource "aws_autoscaling_lifecycle_hook" "default" {
  count                  = "${length(var.asg_names)}"
  autoscaling_group_name = "${element(var.asg_names, count.index)}"

  lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  name                 = "asg-term-hook"
  heartbeat_timeout    = "600"

  notification_target_arn = "${aws_sns_topic.default.arn}"
  role_arn                = "${aws_iam_role.asg_hook.arn}"
}
