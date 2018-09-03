variable "name" {
  default = "ecs_spot_fleet"
}

variable "cluster_name" {}

variable "subnets" {
  type = "list"
}

variable "valid_until" {}

variable "ami_id" {}

variable "iam_fleet_role_arn" {}

variable "instance_type" {
  default = "t2.large"
}

variable "spot_price" {
  default = "0.0928"
}

variable "instance_profile_name" {}

variable "security_groups" {
  type = "list"
}

variable "user_data" {}

variable "key_name" {}

variable "target_capacity" {
  default = 3
}

variable "min_size" {
  default = 1
}

variable "max_size" {
  default = 20
}

variable "allocation_strategy" {
  default = "diversified"
}
