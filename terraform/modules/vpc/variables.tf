variable "project_name" {
  type = string
}

variable "cluster_name" {
  description = "Usado nas tags de descoberta do ALB controller / EKS"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type = bool
}

variable "tags" {
  type    = map(string)
  default = {}
}
