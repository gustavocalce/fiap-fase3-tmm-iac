resource "random_password" "auth_token" {
  length  = 32
  special = false
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "evaluation-service-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "this" {
  name        = "evaluation-service-redis-sg"
  description = "Redis SG for evaluation-service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS nodes"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Replication group de nó único, com criptografia em trânsito habilitada
# (obrigatória para uso de auth token / senha no Redis)
resource "aws_elasticache_replication_group" "this" {
  replication_group_id       = "evaluation-service-redis"
  description                = "Cache de regras de flags para o evaluation-service"
  engine                     = "redis"
  node_type                  = var.node_type
  num_cache_clusters         = 1
  parameter_group_name       = "default.redis7"
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result

  tags = var.tags
}
