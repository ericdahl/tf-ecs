/*
 * Demo service that has special permissions granted to it via an IAM Task Role
 */

data "template_file" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  template = "${file("templates/tasks/demo_iam.json")}"
}

resource "aws_ecs_task_definition" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.demo_iam.rendered}"
  family                = "demo_iam"
  task_role_arn         = "${aws_iam_role.demo_iam.arn}"
}

resource "aws_ecs_service" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  cluster         = "tf-cluster"
  name            = "tf-cluster-demo_iam"
  task_definition = "${aws_ecs_task_definition.demo_iam.arn}"
  desired_count   = "1"

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}

resource "aws_iam_role" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  name = "ecs_service_demo_iam"

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

resource "aws_iam_role_policy" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  name = "ecs_service_demo_iam"
  role = "${aws_iam_role.demo_iam.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1465589882000",
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "1234",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.demo_iam.arn}",
        "${aws_s3_bucket.demo_iam.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  bucket = "tf-demo-iam-2018"
}
