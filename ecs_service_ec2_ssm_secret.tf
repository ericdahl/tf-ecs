data "template_file" "ssm_secret" {
  count    = var.enable_ec2_ssm_secret ? 1 : 0
  template = file("templates/tasks/ssm_secret.json")
}

resource "aws_ecs_task_definition" "ssm_secret" {
  count                 = var.enable_ec2_ssm_secret ? 1 : 0
  container_definitions = data.template_file.ssm_secret[0].rendered
  family                = "ssm_secret"
  execution_role_arn    = aws_iam_role.ssm_secret[0].arn
}

resource "aws_ecs_service" "ssm_secret" {
  count = var.enable_ec2_ssm_secret ? 1 : 0

  cluster         = "tf-cluster"
  name            = "tf-cluster-ssm_secret"
  task_definition = aws_ecs_task_definition.ssm_secret[0].arn
  desired_count   = "1"
}

resource "aws_ssm_parameter" "ssm_secret" {
  count = var.enable_ec2_ssm_secret ? 1 : 0

  name  = "MY_SECRET"
  type  = "SecureString"
  value = "MySecretValue"
}

resource "aws_iam_role" "ssm_secret" {
  count = var.enable_ec2_ssm_secret ? 1 : 0

  name        = "tf-cluster-ssm_secret_execution_role"
  description = "Role used by demo ECS service to pull SSM secrets and populate in environment"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ssm_secret" {
  count = var.enable_ec2_ssm_secret ? 1 : 0

  name = "tf-cluster-ssm_secret_execution_role"
  role = aws_iam_role.ssm_secret[0].id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
{
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters"
      ],
      "Resource": "${aws_ssm_parameter.ssm_secret[0].arn}"
    }
  ]
}
EOF

}

