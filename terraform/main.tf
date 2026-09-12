locals {
  tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
    Cluster   = var.cluster_name
  }

  # Account id originalmente hardcoded nos manifests deste repositório (projeto fase 2)
  old_account_id = "570814275471"

  # Caminhos para arquivos já existentes no repositório, reaproveitados pelos módulos
  k8s_path            = "${path.root}/../K8s"
  alb_iam_policy_json = file("${path.root}/../AWS/alb-controller/iam-policy.json")
  alb_serviceaccount_yaml = replace(
    file("${path.root}/../K8s/base/alb-controller/serviceaccount.yaml"),
    local.old_account_id,
    data.aws_caller_identity.current.account_id,
  )
}

module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.tags
}

module "eks" {
  source = "./modules/eks"

  cluster_name         = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  public_subnet_ids    = module.vpc.public_subnet_ids
  node_instance_types  = var.node_instance_types
  node_min_size        = var.node_min_size
  node_max_size        = var.node_max_size
  node_desired_size    = var.node_desired_size
  tags                 = local.tags
}

module "ecr" {
  source = "./modules/ecr"

  repositories = var.ecr_repositories
  tags         = local.tags
}

module "sqs" {
  source = "./modules/sqs"

  queue_name = var.sqs_queue_name
  tags       = local.tags
}

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = var.dynamodb_analytics_table_name
  tags       = local.tags
}

module "rds" {
  source = "./modules/rds"

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.eks.cluster_security_group_id
  engine_version             = var.rds_engine_version
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  tags                       = local.tags
}

module "elasticache" {
  source = "./modules/elasticache"

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  cluster_security_group_id = module.eks.cluster_security_group_id
  node_type                 = var.redis_node_type
  tags                      = local.tags
}

module "secrets" {
  source = "./modules/secrets"

  databases              = module.rds.databases
  redis_primary_endpoint = module.elasticache.primary_endpoint_address
  redis_auth_token       = module.elasticache.auth_token
  master_key_length      = var.master_key_length
  tags                   = local.tags
}

module "irsa" {
  source = "./modules/irsa"

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  alb_iam_policy_json                    = local.alb_iam_policy_json
  auth_database_url_secret_arn           = module.secrets.auth_database_url_arn
  auth_master_key_secret_arn             = module.secrets.auth_master_key_arn
  flag_database_url_secret_arn           = module.secrets.flag_database_url_arn
  targeting_database_url_secret_arn      = module.secrets.targeting_database_url_arn
  evaluation_redis_url_secret_arn        = module.secrets.evaluation_redis_url_arn
  evaluation_service_api_key_secret_arn = module.secrets.evaluation_service_api_key_arn
  sqs_queue_arn                          = module.sqs.queue_arn
  dynamodb_table_arn                     = module.dynamodb.table_arn
  tags                                    = local.tags
}

module "k8s_addons" {
  source = "./modules/k8s-addons"

  cluster_name                          = module.eks.cluster_name
  aws_region                            = var.aws_region
  vpc_id                                = module.vpc.vpc_id
  alb_serviceaccount_yaml                = local.alb_serviceaccount_yaml
  keda_role_arn                          = module.irsa.role_arns["keda-operator-role"]
  alb_controller_chart_version            = var.alb_controller_chart_version
  keda_chart_version                      = var.keda_chart_version
  secrets_store_csi_driver_chart_version  = var.secrets_store_csi_driver_chart_version

  # Sem depends_on aqui: o provider kubectl/helm/kubernetes já depende de
  # module.eks (host/token), e keda_role_arn já força a dependência de
  # module.irsa. Um depends_on de módulo forçaria os data sources internos
  # (http/kubectl_file_documents) a ficarem "known after apply", quebrando
  # o for_each do aws_provider_installer no plan.
}

# DESLIGADO: os 5 workloads passaram a ser gerenciados pelo ArgoCD (GitOps),
# em gitops/. Manter este módulo ligado faria o Terraform e o ArgoCD brigarem
# pela posse dos Deployments (cada apply/sync desfazendo o outro).
#
# ATENCAO (quem tem acesso ao backend S3): se a infra ja foi aplicada com este
# modulo, os manifests estao no state. Remova-os SEM destruir os workloads que
# o ArgoCD agora possui:
#
#   cd terraform && terraform state rm 'module.k8s_manifests'
#
# module "k8s_manifests" {
#   source = "./modules/k8s-manifests"
#
#   k8s_path       = local.k8s_path
#   account_id     = data.aws_caller_identity.current.account_id
#   old_account_id = local.old_account_id
#
#   depends_on = [module.k8s_addons, module.irsa, module.secrets]
# }
