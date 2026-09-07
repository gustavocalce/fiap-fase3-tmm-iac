output "role_arns" {
  value = { for k, v in aws_iam_role.this : k => v.arn }
}

# Presença destes outputs força a ordenação correta em módulos consumidores
output "attachments_done" {
  value = [
    aws_iam_role_policy_attachment.auth_service_secrets.id,
    aws_iam_role_policy_attachment.flag_service_secrets.id,
    aws_iam_role_policy_attachment.targeting_service_secrets.id,
    aws_iam_role_policy_attachment.evaluation_service.id,
    aws_iam_role_policy_attachment.analytics_service.id,
    aws_iam_role_policy_attachment.keda.id,
    aws_iam_role_policy_attachment.alb_controller.id,
  ]
}
