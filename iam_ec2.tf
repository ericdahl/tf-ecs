data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2" {
  name        = "${var.name}-instance-role"
  description = "Role applied to ECS container instances - EC2 hosts - allowing them to register themselves, pull images from ECR, etc."

  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_policy_attachment" "ec2_ecs" {
  name       = "${aws_ecs_cluster.default.name}-ec2"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_policy_attachment" "ec2_ssm" {
  name       = "${aws_ecs_cluster.default.name}-ec2"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "${aws_iam_role.ec2.name}-instance-profile"
  role = aws_iam_role.ec2.name
}