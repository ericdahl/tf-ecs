output "ami_id" {
  value = "${data.aws_ami.ecs.id}"
}

output "iam_role_ecs_service_name" {
  value = "${aws_iam_role.ecs_service.name}"
}

output "iam_role_fleet_arn" {
  value = "${aws_iam_role.fleet.arn}"
}

output "iam_instance_profile_name" {
  value = "${aws_iam_instance_profile.default.name}"
}

output "user-data" {
  value = "${data.template_file.cloud_init.rendered}"
}

output "cluster_name" {
  value = "${aws_ecs_cluster.default.name}"
}
