resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sub1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub2" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sub3" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "sub1" {
  route_table_id = "${aws_route_table.default.id}"
  subnet_id      = "${aws_subnet.sub1.id}"
}

resource "aws_route_table_association" "sub2" {
  route_table_id = "${aws_route_table.default.id}"
  subnet_id      = "${aws_subnet.sub2.id}"
}

resource "aws_route_table_association" "sub3" {
  route_table_id = "${aws_route_table.default.id}"
  subnet_id      = "${aws_subnet.sub3.id}"
}

resource "aws_security_group" "allow_22" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_22_0" {
  security_group_id = "${aws_security_group.allow_22.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "allow_80" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_80_0" {
  security_group_id = "${aws_security_group.allow_80.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80

  //  cidr_blocks = ["0.0.0.0/0"]
  cidr_blocks = ["24.5.3.85/32"]
}

resource "aws_security_group" "allow_egress" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_egress_0" {
  security_group_id = "${aws_security_group.allow_egress.id}"
  type              = "egress"
  protocol          = "-1"
  from_port         = -1
  to_port           = -1
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "lb" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "allow_lb" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_lb_0" {
  security_group_id = "${aws_security_group.allow_lb.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80

  source_security_group_id = "${aws_security_group.lb.id}"
}

resource "aws_security_group" "client" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group" "allow_client" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_security_group_rule" "allow_client_0" {
  security_group_id = "${aws_security_group.allow_client.id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80

  source_security_group_id = "${aws_security_group.client.id}"
}
