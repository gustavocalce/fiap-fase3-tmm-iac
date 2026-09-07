variable "cluster_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_serviceaccount_yaml" {
  description = "Conteúdo de K8s/base/alb-controller/serviceaccount.yaml, lido pela raiz"
  type        = string
}

variable "keda_role_arn" {
  type = string
}

variable "alb_controller_chart_version" {
  type = string
}

variable "keda_chart_version" {
  type = string
}

variable "secrets_store_csi_driver_chart_version" {
  type = string
}
