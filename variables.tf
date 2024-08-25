variable "name" {
  default = "tf-ecs"
}

variable "asg_desired_size" {
  default = 3
}

variable "asg_min_size" {
  default = 3
}

variable "asg_max_size" {
  default = 3
}

variable "ecs_asg_desired_size" {
  default = 10
}

variable "ecs_asg_spot_desired_size" {
  default = 3
}

variable "ecs_spot_fleet_desired_size" {
  default = 3
}

/*
 * Service/Feature toggles
 */
variable "enable_fargate_httpbin" {
  default = false
}

variable "enable_ec2_signalfx" {
  default = false
}

variable "signalfx_api_key" {
  default = ""
}

variable "enable_ec2_demo_iam" {
  default = false
}

variable "enable_ec2_fluentd" {
  default = false
}

variable "enable_ec2_httpbin" {
  default = false
}

variable "enable_ec2_ssm_secret" {
  default = false
}

variable "enable_ec2_ghost" {
  default = false
}

variable "enable_ec2_demo_service_discovery" {
  default = false
}

variable "ec2_httpbin_max_capacity" {
  default = 30
}

variable "ec2_httpbin_min_capacity" {
  default = 12
}

