output "alb_dns_name" {
  value = "${aws_alb.default.dns_name}"
}

output "aws_alb_target_group.default.arn" {
  value = "${aws_alb_target_group.default.arn}"
}

output "aws_instance.jumphost.public_ip" {
  value = "${aws_instance.jumphost.public_ip}"
}