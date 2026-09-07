resource "random_password" "auth_master_key" {
  length  = var.master_key_length
  special = false
}

# ---------------------------------------------------------------------------
# auth-service: DATABASE_URL e MASTER_KEY, um secret por chave conforme
# esperado pelo K8s/auth-service/secretproviderclass.yaml
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "auth_database_url" {
  name = "auth-service/DATABASE_URL"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "auth_database_url" {
  secret_id     = aws_secretsmanager_secret.auth_database_url.id
  secret_string = "postgres://${var.databases["auth"].master_username}:${var.databases["auth"].password}@${var.databases["auth"].address}:5432/${var.databases["auth"].db_name}"
}

resource "aws_secretsmanager_secret" "auth_master_key" {
  name = "auth-service/MASTER_KEY"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "auth_master_key" {
  secret_id     = aws_secretsmanager_secret.auth_master_key.id
  secret_string = random_password.auth_master_key.result
}

# ---------------------------------------------------------------------------
# flag-service / targeting-service: DATABASE_URL
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "flag_database_url" {
  name = "flag-service/DATABASE_URL"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "flag_database_url" {
  secret_id     = aws_secretsmanager_secret.flag_database_url.id
  secret_string = "postgres://${var.databases["flag"].master_username}:${var.databases["flag"].password}@${var.databases["flag"].address}:5432/${var.databases["flag"].db_name}"
}

resource "aws_secretsmanager_secret" "targeting_database_url" {
  name = "targeting-service/DATABASE_URL"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "targeting_database_url" {
  secret_id     = aws_secretsmanager_secret.targeting_database_url.id
  secret_string = "postgres://${var.databases["targeting"].master_username}:${var.databases["targeting"].password}@${var.databases["targeting"].address}:5432/${var.databases["targeting"].db_name}"
}

# ---------------------------------------------------------------------------
# evaluation-service: REDIS_URL e SERVICE_API_KEY
# SERVICE_API_KEY só pode ser gerada de verdade chamando a API do
# auth-service (POST /auth/admin/keys) após o deploy — aqui criamos um valor
# placeholder e marcamos para não ser revertido por applies futuros; atualize
# manualmente com `aws secretsmanager put-secret-value` conforme o README.
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "evaluation_redis_url" {
  name = "evaluation-service/REDIS_URL"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "evaluation_redis_url" {
  secret_id     = aws_secretsmanager_secret.evaluation_redis_url.id
  secret_string = "redis://:${var.redis_auth_token}@${var.redis_primary_endpoint}:6379"
}

resource "aws_secretsmanager_secret" "evaluation_service_api_key" {
  name = "evaluation-service/SERVICE_API_KEY"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "evaluation_service_api_key" {
  secret_id     = aws_secretsmanager_secret.evaluation_service_api_key.id
  secret_string = "REPLACE_ME_AFTER_CREATING_KEY_VIA_AUTH_SERVICE"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
