variable "cluster_name" {}

variable "asg_name" {}

variable "memory_reservation_target" {
  default = 70
}

variable "cpu_reservation_target" {
  default = 70
}