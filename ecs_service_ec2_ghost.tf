resource "aws_ecs_task_definition" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  family = "ghost"

  container_definitions = templatefile("templates/tasks/ghost.json", {
    url           = "http://${aws_alb.ecs_service_ghost[0].dns_name}"
    database_host = aws_rds_cluster.ghost[0].endpoint
    database_name = aws_rds_cluster.ghost[0].database_name
    database_user = aws_rds_cluster.ghost[0].master_username
    database_port = aws_rds_cluster.ghost[0].port
  })
}

resource "aws_ecs_service" "ghost" {
  count = var.enable_ec2_ghost ? 1 : 0

  cluster         = aws_ecs_cluster.default.name
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

  # https://github.com/hashicorp/terraform-provider-aws/issues/11351
  lifecycle {
    ignore_changes = [
      capacity_provider_strategy
    ]
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
  deregistration_delay = 0

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

  db_subnet_group_name   = aws_db_subnet_group.ghost[0].name
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

output "ghost" {
  value = join("", aws_alb.ecs_service_ghost.*.dns_name)
}

