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


  # IAM Task role granting access to S3 list operation
  # Inside the container, AWS SDK will
  #
  # curl 169.254.170.2$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
  #
  # where `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` is an env variable populated
  # by ECS which looks like
  #
  # /v2/credentials/8fb1bd0d-9bdd-4de5-9735-59349f935bd7
  #
  # This returns a JSON response with a key/secret/temp token, similar to the
  # standard EC2 metadata IAM endpoint.
  #
  # Typical ECS container host then has iptables rules to pre-route/redirect
  #
  # 169.254.170.2/32 --> 127.0.0.1:51679
  #
  # ecs-agent docker container listens at 127.0.0.1:51679 (host networking)
  #
  # Every AWS SDK is expected to check for `$AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`
  # and query it for credentials (example: https://github.com/aws/aws-sdk-ruby/blob/fd0373ea9/gems/aws-sdk-core/lib/aws-sdk-core/credential_provider_chain.rb#L86)

  # more info at https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html

  task_role_arn         = "${aws_iam_role.demo_iam.arn}"
}

resource "aws_ecs_service" "demo_iam" {
  count = "${var.enable_demo_iam == "true" ? 1 : 0}"

  cluster         = "tf-cluster"
  name            = "tf-cluster-demo_iam"
  task_definition = "${aws_ecs_task_definition.demo_iam.arn}"
  desired_count   = "1"
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
