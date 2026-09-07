variable "aws_region" {
  description = "Região AWS onde toda a infraestrutura será criada"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Profile do ~/.aws/credentials a usar (chave de acesso de longa duração). Null usa a cadeia padrão de credenciais."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Prefixo usado em tags e nomes de recursos"
  type        = string
  default     = "toggle-master"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "eks-tc3-prod-001"
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes do EKS"
  type        = string
  default     = "1.30"
}

# ---------------------------------------------------------------------------
# Rede
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs utilizadas (3 subnets públicas + 3 privadas)"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "single_nat_gateway" {
  description = "Se true, cria apenas 1 NAT Gateway (economia). Se false, 1 por AZ (alta disponibilidade)"
  type        = bool
  default     = true
}

# ---------------------------------------------------------------------------
# EKS Node Group
# ---------------------------------------------------------------------------

variable "node_instance_types" {
  description = "Tipos de instância do managed node group"
  type        = list(string)
  default     = ["c7i-flex.large"]
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_desired_size" {
  type    = number
  default = 2
}

# ---------------------------------------------------------------------------
# ECR / SQS / DynamoDB
# ---------------------------------------------------------------------------

variable "ecr_repositories" {
  description = "Repositórios ECR a criar (um por microserviço)"
  type        = list(string)
  default = [
    "fiap-fase2/auth-service",
    "fiap-fase2/flag-service",
    "fiap-fase2/targeting-service",
    "fiap-fase2/evaluation-service",
    "fiap-fase2/analytics-service",
  ]
}

variable "sqs_queue_name" {
  type    = string
  default = "ToggleMasterQueue"
}

variable "dynamodb_analytics_table_name" {
  type    = string
  default = "ToggleMasterAnalytics"
}

# ---------------------------------------------------------------------------
# RDS (auth-service, flag-service, targeting-service)
# ---------------------------------------------------------------------------

variable "rds_engine_version" {
  type    = string
  default = "17.5"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_allocated_storage" {
  type    = number
  default = 20
}

# ---------------------------------------------------------------------------
# ElastiCache (evaluation-service)
# ---------------------------------------------------------------------------

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

# ---------------------------------------------------------------------------
# Helm chart versions dos add-ons
# ---------------------------------------------------------------------------

variable "alb_controller_chart_version" {
  type    = string
  default = "1.8.2"
}

variable "keda_chart_version" {
  type    = string
  default = "2.15.1"
}

variable "secrets_store_csi_driver_chart_version" {
  type    = string
  default = "1.4.5"
}

# ---------------------------------------------------------------------------
# Tags de imagem atualmente publicadas (usadas apenas para referência/outputs)
# ---------------------------------------------------------------------------

variable "master_key_length" {
  description = "Tamanho da MASTER_KEY gerada para o auth-service"
  type        = number
  default     = 48
}
