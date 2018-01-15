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
  role       = "${aws_iam_role.asg_lambda.name}"
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.asg_lambda.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
          "autoscaling:CompleteLifecycleAction",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeHosts",
          "ecs:ListContainerInstances",
          "ecs:SubmitContainerStateChange",
          "ecs:SubmitTaskStateChange",
          "ecs:DescribeContainerInstances",
          "ecs:UpdateContainerInstancesState",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
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
  role = "${aws_iam_role.asg_hook.id}"

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
