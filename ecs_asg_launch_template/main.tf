resource "aws_autoscaling_group" "default" {
  name = "var.name"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_size

  vpc_zone_identifier = var.subnets

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
        version = "$Latest"
      }


//      overrides = [
//        {
//          instance_type = "t2.medium"
//        },
//        {
//          instance_type = "t2.large"
//        },
//        {
//          instance_type = "m1.small"
//        },
//        {
//          instance_type = "m3.medium"
//        },
//        {
//          instance_type = "c4.large"
//        },
//      ]


//        override = [
//          for o in var.overrides: {
//            instance_type = o
//        }
//        ]

      dynamic override {
        for_each = var.overrides
        content {
          instance_type = override.value["instance_type"]
        }
      }
    }

    instances_distribution {
      # 0% means no on-demand
      on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
    }
  }
}

resource "aws_launch_template" "default" {
  name = var.name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = var.security_groups

  user_data = base64encode(var.user_data)
}
