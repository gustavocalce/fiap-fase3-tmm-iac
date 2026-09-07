output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "sqs_queue_url" {
  value = module.sqs.queue_url
}

output "dynamodb_analytics_table" {
  value = module.dynamodb.table_name
}

output "rds_endpoints" {
  value     = { for k, v in module.rds.databases : k => v.address }
  sensitive = true
}

output "redis_primary_endpoint" {
  value = module.elasticache.primary_endpoint_address
}

output "irsa_role_arns" {
  value = module.irsa.role_arns
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "next_manual_step" {
  value = "Após o apply, crie a API key do evaluation-service via POST /auth/admin/keys e atualize o secret evaluation-service/SERVICE_API_KEY com 'aws secretsmanager put-secret-value'."
}

