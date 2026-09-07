variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "node_type" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
