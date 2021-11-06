data "template_file" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  template = file("templates/tasks/ghost.json")

  vars = {
    url           = "http://${aws_alb.ecs_service_ghost[0].dns_name}"
    database_host = aws_rds_cluster.ghost[0].endpoint
    database_name = aws_rds_cluster.ghost[0].database_name
    database_user = aws_rds_cluster.ghost[0].master_username
    database_port = aws_rds_cluster.ghost[0].port
  }
}

resource "aws_ecs_task_definition" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  container_definitions = data.template_file.ghost[0].rendered
  family                = "ghost"
}

resource "aws_ecs_service" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  cluster         = "tf-cluster"
  name            = "tf-cluster-ghost"
  task_definition = aws_ecs_task_definition.ghost[0].arn
  desired_count   = "2"

  enable_ecs_managed_tags = "true"
  propagate_tags          = "SERVICE"

  # to avoid possible race condition error on creation
  depends_on = [aws_alb.ecs_service_ghost]

  load_balancer {
    target_group_arn = aws_alb_target_group.ghost[0].arn
    container_name   = "ghost"
    container_port   = 2368
  }
}

resource "aws_alb" "ecs_service_ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  name = "ghost-ec2"

  subnets = [
    module.vpc.subnet_public1,
    module.vpc.subnet_public2,
    module.vpc.subnet_public3,
  ]

  security_groups = [
    module.vpc.sg_allow_egress,
    module.vpc.sg_allow_80,
  ]
}

resource "aws_alb_listener" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  default_action {
    target_group_arn = aws_alb_target_group.ghost[0].arn
    type             = "forward"
  }

  load_balancer_arn = aws_alb.ecs_service_ghost[0].arn
  port              = 80
}

resource "aws_alb_target_group" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  name                 = "ghost-ec2"
  vpc_id               = module.vpc.vpc_id
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
  count = var.enable_ec2_ghost ? 1 : 0

  cluster_identifier = "ghost"

  engine         = "aurora-mysql"
  engine_version = "5.7.12"

  database_name   = "ghostdb"
  master_username = "ghost"
  master_password = "ghost_password"

  skip_final_snapshot       = true
  final_snapshot_identifier = "ghost"

  db_subnet_group_name = aws_db_subnet_group.ghost[0].name
  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibility in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  vpc_security_group_ids = [module.vpc.sg_allow_vpc]
}

resource "aws_rds_cluster_instance" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  cluster_identifier = aws_rds_cluster.ghost[0].id

  engine         = "aurora-mysql"
  engine_version = "5.7.12"

  instance_class = "db.t2.small"
}

resource "aws_db_subnet_group" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  subnet_ids = [
    module.vpc.subnet_private1,
    module.vpc.subnet_private2,
    module.vpc.subnet_private3,
  ]
}

//
//resource "aws_appautoscaling_target" "ecs_service_ghost" {
//  count = "${var.enable_ec2_ghost ? 1 : 0}"
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
//  count = "${var.enable_ec2_ghost ? 1 : 0}"
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
