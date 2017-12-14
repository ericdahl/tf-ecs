output "alb_dns_name" {
  value = "${aws_alb.default.dns_name}"
}


output "aws_alb_target_group.default.arn" {
  value = "${aws_alb_target_group.default.arn}"
}
