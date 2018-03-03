resource "aws_iam_role" "ec2_role" {
  name        = "${var.cluster_name}-instance-role"
  description = "Role applied to ECS container instances - EC2 hosts - allowing them to register themselves, pull images from ECR, etc."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "default" {
  name       = "${var.cluster_name}-ec2"
  roles      = ["${aws_iam_role.ec2_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "default" {
  name = "${var.cluster_name}-instance-profile"
  role = "${aws_iam_role.ec2_role.name}"
}

resource "aws_iam_role" "ecs_service" {
  name        = "${var.cluster_name}-service-role"
  description = "Role applied to ECS Services, allowing them to register in ELB/ALB, etc"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "ecs_service" {
  name       = "${var.cluster_name}-ecs-service"
  roles      = ["${aws_iam_role.ecs_service.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_iam_role" "fleet" {
  name = "iam_fleet_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fleet_terminate_name" {
  role       = "${aws_iam_role.fleet.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
