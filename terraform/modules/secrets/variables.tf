variable "databases" {
  description = "Saída do módulo rds (module.rds.databases)"
  type = map(object({
    address         = string
    db_name         = string
    master_username = string
    password        = string
  }))
  sensitive = true
}

variable "redis_primary_endpoint" {
  type = string
}

variable "redis_auth_token" {
  type      = string
  sensitive = true
}

variable "master_key_length" {
  type    = number
  default = 48
}

variable "tags" {
  type    = map(string)
  default = {}
}
