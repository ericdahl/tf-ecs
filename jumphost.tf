resource "aws_security_group" "jumphost" {
  vpc_id = module.vpc.vpc_id
  name = "jumphost"

  tags = {
    Name = "jumphost"
  }
}

resource "aws_security_group_rule" "jumphost_egress" {
  security_group_id = aws_security_group.jumphost.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jumphost_ingress_ssh_admin" {
  security_group_id = aws_security_group.jumphost.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_cidr]
}

data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type          = "t2.small"
  subnet_id              = module.vpc.subnet_public1
  vpc_security_group_ids = [aws_security_group.jumphost.id]
  key_name               = aws_key_pair.key.key_name

  tags = {
    Name = "jumphost"
  }
}

