locals {
  services = {
    auth = {
      identifier      = "auth-service-db"
      db_name         = "auth_service_db"
      master_username = "auth_service_user"
    }
    flag = {
      identifier      = "flag-service-db"
      db_name         = "flag_service_db"
      master_username = "flag_service_user"
    }
    targeting = {
      identifier      = "targeting-service-db"
      db_name         = "targeting_service_db"
      master_username = "targeting_service_user"
    }
  }
}

resource "random_password" "this" {
  for_each = local.services

  length  = 24
  special = false
}

resource "aws_db_subnet_group" "this" {
  for_each = local.services

  name       = "${each.value.identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "this" {
  for_each = local.services

  name        = "${each.value.identifier}-sg"
  description = "RDS SG for ${each.key}-service"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
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

resource "aws_db_instance" "this" {
  for_each = local.services

  identifier              = each.value.identifier
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_type            = "gp2"
  db_name                 = each.value.db_name
  username                = each.value.master_username
  password                = random_password.this[each.key].result
  db_subnet_group_name    = aws_db_subnet_group.this[each.key].name
  vpc_security_group_ids  = [aws_security_group.this[each.key].id]
  publicly_accessible     = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = var.tags
}
