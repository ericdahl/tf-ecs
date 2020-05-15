output "name" {
  value = "${aws_autoscaling_group.default.name}"
}

output "asg_scale_up_arn" {
  value = "${aws_autoscaling_policy.scale_up.arn}"
}

output "asg_scale_down_arn" {
  value = "${aws_autoscaling_policy.scale_down.arn}"
}
