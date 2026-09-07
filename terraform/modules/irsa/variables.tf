variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}

variable "alb_iam_policy_json" {
  description = "Conteúdo do AWS/alb-controller/iam-policy.json, lido pela raiz"
  type        = string
}

variable "auth_database_url_secret_arn" {
  type = string
}

variable "auth_master_key_secret_arn" {
  type = string
}

variable "flag_database_url_secret_arn" {
  type = string
}

variable "targeting_database_url_secret_arn" {
  type = string
}

variable "evaluation_redis_url_secret_arn" {
  type = string
}

variable "evaluation_service_api_key_secret_arn" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
