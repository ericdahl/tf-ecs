resource "aws_autoscaling_group" "default" {
  name = var.name

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_size

  vpc_zone_identifier = [
    module.vpc.subnet_private1,
    module.vpc.subnet_private2,
    module.vpc.subnet_private3,
  ]

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.default.id
        version            = aws_launch_template.default.latest_version
      }

      override {
        instance_requirements {
          cpu_manufacturers = [
            "amd",
            "intel",
          ]
          memory_mib {
            min = 2048
            max = 8192
          }
          vcpu_count {
            min = 1
            max = 4
          }

          accelerator_count {
            max = 0
          }
          burstable_performance = "included"

          on_demand_max_price_percentage_over_lowest_price = 65
        }
      }
    }

    instances_distribution {
      # 0% means no on-demand
      on_demand_percentage_above_base_capacity = 100
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 0
    }
  }
}


resource "aws_launch_template" "default" {
  name = var.name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_ec2.name
  }

  image_id      = data.aws_ssm_parameter.ecs_amazon_linux_2.value
  instance_type = "t3.small"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.ecs_instance.id]

  user_data = base64encode(<<EOF
#!/bin/bash
echo "ECS_CLUSTER=${var.name}" >> /etc/ecs/ecs.config
EOF
  )

  #   user_data_bottlerocket = <<EOF
  # [settings.ecs]
  # cluster = "${var.name}"
  #
  # [settings.host-containers.admin]
  # enabled = true
  # EOF
}
