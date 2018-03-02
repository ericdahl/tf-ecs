variable "key_name" {}

variable "desired_size" {
  default = 3
}

variable "admin_cidr" {
  default = "0.0.0.0/0"
}

variable "enable_fargate" {
  default = "false"
}

variable "enable_signalfx" {
  default = "false"
}

variable "signalfx_api_key" {
  default = ""
}

variable "ecs_asg_desired_size" {
  default = 0
}

variable "ecs_asg_spot_desired_size" {
  default = 3
}

variable "ecs_spot_fleet_desired_size" {
  default = 0
}
