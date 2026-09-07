output "alb_controller_status" {
  value = helm_release.aws_load_balancer_controller.status
}

output "keda_status" {
  value = helm_release.keda.status
}

output "csi_driver_status" {
  value = helm_release.secrets_store_csi_driver.status
}
