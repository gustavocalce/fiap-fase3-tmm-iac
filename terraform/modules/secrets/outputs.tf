output "auth_database_url_arn" {
  value = aws_secretsmanager_secret.auth_database_url.arn
}

output "auth_master_key_arn" {
  value = aws_secretsmanager_secret.auth_master_key.arn
}

output "flag_database_url_arn" {
  value = aws_secretsmanager_secret.flag_database_url.arn
}

output "targeting_database_url_arn" {
  value = aws_secretsmanager_secret.targeting_database_url.arn
}

output "evaluation_redis_url_arn" {
  value = aws_secretsmanager_secret.evaluation_redis_url.arn
}

output "evaluation_service_api_key_arn" {
  value = aws_secretsmanager_secret.evaluation_service_api_key.arn
}

# Referências agregadas às secret_version, usadas apenas para forçar
# dependência de ordenação a partir de outros módulos (ex: k8s-manifests)
output "version_ids" {
  value = [
    aws_secretsmanager_secret_version.auth_database_url.version_id,
    aws_secretsmanager_secret_version.auth_master_key.version_id,
    aws_secretsmanager_secret_version.flag_database_url.version_id,
    aws_secretsmanager_secret_version.targeting_database_url.version_id,
    aws_secretsmanager_secret_version.evaluation_redis_url.version_id,
    aws_secretsmanager_secret_version.evaluation_service_api_key.version_id,
  ]
}
