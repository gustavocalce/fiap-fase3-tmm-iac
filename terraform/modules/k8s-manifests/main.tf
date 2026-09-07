# ---------------------------------------------------------------------------
# auth-service
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "auth_namespace" {
  yaml_body = file("${var.k8s_path}/auth-service/namespace.yaml")
}

resource "kubectl_manifest" "auth_serviceaccount" {
  yaml_body  = replace(file("${var.k8s_path}/auth-service/serviceaccount.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.auth_namespace]
}

resource "kubectl_manifest" "auth_secretproviderclass" {
  yaml_body  = file("${var.k8s_path}/auth-service/secretproviderclass.yaml")
  depends_on = [kubectl_manifest.auth_serviceaccount]
}

resource "kubectl_manifest" "auth_service_k8s" {
  yaml_body  = file("${var.k8s_path}/auth-service/service.yaml")
  depends_on = [kubectl_manifest.auth_namespace]
}

resource "kubectl_manifest" "auth_deployment" {
  yaml_body  = replace(file("${var.k8s_path}/auth-service/deployment.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.auth_secretproviderclass, kubectl_manifest.auth_service_k8s]
  # ECR ainda pode estar sem imagem publicada; não bloquear o apply esperando o rollout
  wait_for_rollout = false
}

resource "kubectl_manifest" "auth_ingress" {
  yaml_body  = file("${var.k8s_path}/auth-service/ingress.yaml")
  depends_on = [kubectl_manifest.auth_deployment]
}

# ---------------------------------------------------------------------------
# flag-service
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "flag_namespace" {
  yaml_body = file("${var.k8s_path}/flag-service/namespace.yaml")
}

resource "kubectl_manifest" "flag_serviceaccount" {
  yaml_body  = replace(file("${var.k8s_path}/flag-service/serviceaccount.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.flag_namespace]
}

resource "kubectl_manifest" "flag_secretproviderclass" {
  yaml_body  = file("${var.k8s_path}/flag-service/secretproviderclass.yaml")
  depends_on = [kubectl_manifest.flag_serviceaccount]
}

resource "kubectl_manifest" "flag_service_k8s" {
  yaml_body  = file("${var.k8s_path}/flag-service/service.yaml")
  depends_on = [kubectl_manifest.flag_namespace]
}

resource "kubectl_manifest" "flag_deployment" {
  yaml_body  = replace(file("${var.k8s_path}/flag-service/deployment.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.flag_secretproviderclass, kubectl_manifest.flag_service_k8s]
  wait_for_rollout = false
}

resource "kubectl_manifest" "flag_ingress" {
  yaml_body  = file("${var.k8s_path}/flag-service/ingress.yaml")
  depends_on = [kubectl_manifest.flag_deployment]
}

# ---------------------------------------------------------------------------
# targeting-service (depende do auth-service estar no ar)
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "targeting_namespace" {
  yaml_body = file("${var.k8s_path}/targeting-service/namespace.yaml")
}

resource "kubectl_manifest" "targeting_serviceaccount" {
  yaml_body  = replace(file("${var.k8s_path}/targeting-service/serviceaccount.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.targeting_namespace]
}

resource "kubectl_manifest" "targeting_secretproviderclass" {
  yaml_body  = file("${var.k8s_path}/targeting-service/secretproviderclass.yaml")
  depends_on = [kubectl_manifest.targeting_serviceaccount]
}

resource "kubectl_manifest" "targeting_service_k8s" {
  yaml_body  = file("${var.k8s_path}/targeting-service/service.yaml")
  depends_on = [kubectl_manifest.targeting_namespace]
}

resource "kubectl_manifest" "targeting_deployment" {
  yaml_body = replace(file("${var.k8s_path}/targeting-service/deployment.yaml"), var.old_account_id, var.account_id)
  wait_for_rollout = false
  depends_on = [
    kubectl_manifest.targeting_secretproviderclass,
    kubectl_manifest.targeting_service_k8s,
    kubectl_manifest.auth_deployment,
  ]
}

resource "kubectl_manifest" "targeting_ingress" {
  yaml_body  = file("${var.k8s_path}/targeting-service/ingress.yaml")
  depends_on = [kubectl_manifest.targeting_deployment]
}

# ---------------------------------------------------------------------------
# evaluation-service (depende de flag-service e targeting-service)
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "evaluation_namespace" {
  yaml_body = file("${var.k8s_path}/evaluation-service/namespace.yaml")
}

resource "kubectl_manifest" "evaluation_serviceaccount" {
  yaml_body  = replace(file("${var.k8s_path}/evaluation-service/serviceaccount.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.evaluation_namespace]
}

resource "kubectl_manifest" "evaluation_secretproviderclass" {
  yaml_body  = file("${var.k8s_path}/evaluation-service/secretproviderclass.yaml")
  depends_on = [kubectl_manifest.evaluation_serviceaccount]
}

resource "kubectl_manifest" "evaluation_service_k8s" {
  yaml_body  = file("${var.k8s_path}/evaluation-service/service.yaml")
  depends_on = [kubectl_manifest.evaluation_namespace]
}

resource "kubectl_manifest" "evaluation_deployment" {
  yaml_body = replace(file("${var.k8s_path}/evaluation-service/deployment.yaml"), var.old_account_id, var.account_id)
  wait_for_rollout = false
  depends_on = [
    kubectl_manifest.evaluation_secretproviderclass,
    kubectl_manifest.evaluation_service_k8s,
    kubectl_manifest.flag_deployment,
    kubectl_manifest.targeting_deployment,
  ]
}

resource "kubectl_manifest" "evaluation_ingress" {
  yaml_body  = file("${var.k8s_path}/evaluation-service/ingress.yaml")
  depends_on = [kubectl_manifest.evaluation_deployment]
}

# ---------------------------------------------------------------------------
# analytics-service (depende da fila SQS, DynamoDB e do KEDA já instalado)
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "analytics_namespace" {
  yaml_body = file("${var.k8s_path}/analytics-service/namespace.yaml")
}

resource "kubectl_manifest" "analytics_serviceaccount" {
  yaml_body  = replace(file("${var.k8s_path}/analytics-service/serviceaccount.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.analytics_namespace]
}

resource "kubectl_manifest" "analytics_service_k8s" {
  yaml_body  = file("${var.k8s_path}/analytics-service/service.yaml")
  depends_on = [kubectl_manifest.analytics_namespace]
}

resource "kubectl_manifest" "analytics_deployment" {
  yaml_body  = replace(file("${var.k8s_path}/analytics-service/deployment.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.analytics_serviceaccount, kubectl_manifest.analytics_service_k8s]
  wait_for_rollout = false
}

resource "kubectl_manifest" "analytics_keda_trigger_auth" {
  yaml_body  = file("${var.k8s_path}/analytics-service/keda-trigger-auth.yaml")
  depends_on = [kubectl_manifest.analytics_deployment]
}

resource "kubectl_manifest" "analytics_scaledobject" {
  yaml_body  = replace(file("${var.k8s_path}/analytics-service/scaledobject.yaml"), var.old_account_id, var.account_id)
  depends_on = [kubectl_manifest.analytics_keda_trigger_auth]
}
