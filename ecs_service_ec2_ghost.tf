data "template_file" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  template = "${file("templates/tasks/ghost.json")}"

  vars {
    url           = "http://${aws_alb.ecs_service_ghost.dns_name}"
    database_host = "${aws_rds_cluster.ghost.endpoint}"
    database_name = "${aws_rds_cluster.ghost.database_name}"
    database_user = "${aws_rds_cluster.ghost.master_username}"
    database_port = "${aws_rds_cluster.ghost.port}"
  }
}

resource "aws_ecs_task_definition" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.ghost.rendered}"
  family                = "ghost"
}

resource "aws_ecs_service" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  cluster         = "tf-cluster"
  name            = "tf-cluster-ghost"
  task_definition = "${aws_ecs_task_definition.ghost.arn}"
  desired_count   = "2"

  iam_role = "${module.ecs.iam_role_ecs_service_name}"

  # to avoid possible race condition error on creation
  depends_on = ["aws_alb.ecs_service_ghost"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.ghost.arn}"
    container_name   = "ghost"
    container_port   = 2368
  }
}

resource "aws_alb" "ecs_service_ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  name = "ghost-ec2"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_80}",
  ]
}

resource "aws_alb_listener" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  default_action {
    target_group_arn = "${aws_alb_target_group.ghost.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.ecs_service_ghost.arn}"
  port              = 80
}

resource "aws_alb_target_group" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  name                 = "ghost-ec2"
  vpc_id               = "${module.vpc.vpc_id}"
  port                 = 2368
  protocol             = "HTTP"
  deregistration_delay = 5

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 5
    timeout             = 2
  }
}

resource "aws_rds_cluster" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  cluster_identifier = "ghost"

  engine         = "aurora-mysql"
  engine_version = "5.7.12"

  database_name   = "ghostdb"
  master_username = "ghost"
  master_password = "ghost_password"

  skip_final_snapshot       = true
  final_snapshot_identifier = "ghost"

  db_subnet_group_name   = "${aws_db_subnet_group.ghost.name}"
  vpc_security_group_ids = ["${module.vpc.sg_allow_vpc}"]
}

resource "aws_rds_cluster_instance" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  cluster_identifier = "${aws_rds_cluster.ghost.id}"

  engine         = "aurora-mysql"
  engine_version = "5.7.12"

  instance_class     = "db.t2.small"
}

resource "aws_db_subnet_group" "ghost" {
  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"

  subnet_ids = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]
}

//
//resource "aws_appautoscaling_target" "ecs_service_ghost" {
//  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"
//
//  max_capacity       = "${var.ec2_ghost_max_capacity}"
//  min_capacity       = "${var.ec2_ghost_min_capacity}"
//  resource_id        = "service/${module.ecs.cluster_name}/${aws_ecs_service.ghost.name}"
//  role_arn           = "arn:aws:iam::689973912904:role/aws-service-role/ecs.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_ECSService"
//  scalable_dimension = "ecs:service:DesiredCount"
//  service_namespace  = "ecs"
//}
//
//
//resource "aws_appautoscaling_policy" "ecs_service_ghost_target_tracking" {
//  count = "${var.enable_ec2_ghost == "true" ? 1 : 0}"
//
//  name                    = "ecs_service_ghost_target_tracking"
//  policy_type             = "TargetTrackingScaling"
//  resource_id             = "${aws_appautoscaling_target.ecs_service_ghost.resource_id}"
//  scalable_dimension      = "${aws_appautoscaling_target.ecs_service_ghost.scalable_dimension}"
//  service_namespace       = "${aws_appautoscaling_target.ecs_service_ghost.service_namespace}"
//
//  target_tracking_scaling_policy_configuration {
//    target_value = 30
//
//    predefined_metric_specification {
//      predefined_metric_type = "ALBRequestCountPerTarget"
//      resource_label = "${aws_alb.ecs_service_ghost.arn_suffix}/${aws_alb_target_group.ghost.arn_suffix}"
//    }
//  }
//
//  depends_on = ["aws_appautoscaling_target.ecs_service_ghost"]
//}

