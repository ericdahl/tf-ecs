resource "aws_iam_role" "asg_lambda" {
  name = "asg_lambda"

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

resource "aws_iam_role_policy_attachment" "default" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.asg_lambda.name
}

data "template_file" "iam_drainer_policy" {
  template = file("${path.module}/templates/iam_drainer_policy.json")

  vars {
    cluster_name = var.cluster_name
  }
}

resource "aws_iam_policy" "iam_drainer_policy" {
  name = "iam_drainer_policy"

  policy = data.template_file.iam_drainer_policy.rendered
}

resource "aws_iam_role_policy_attachment" "iam_drainer_policy" {
  policy_arn = aws_iam_policy.iam_drainer_policy.arn
  role = aws_iam_role.asg_hook.name
}

resource "aws_iam_role" "asg_hook" {
  name = "asg_hook"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "asg_hook_policy" {
  name = "test_policy"
  role = aws_iam_role.asg_hook.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:sns:*:*:*asg-drainer"
    }
  ]
}
EOF
}
