# ---------------------------------------------------------------------------
# Secrets Store CSI Driver + AWS provider plugin
# ---------------------------------------------------------------------------

resource "helm_release" "secrets_store_csi_driver" {
  name             = "csi-secrets-store"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.secrets_store_csi_driver_chart_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }
}

data "http" "aws_provider_installer" {
  url = "https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
}

data "kubectl_file_documents" "aws_provider_installer" {
  content = data.http.aws_provider_installer.response_body
}

resource "kubectl_manifest" "aws_provider_installer" {
  for_each  = data.kubectl_file_documents.aws_provider_installer.manifests
  yaml_body = each.value

  depends_on = [helm_release.secrets_store_csi_driver]
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller
# ---------------------------------------------------------------------------

resource "kubectl_manifest" "alb_controller_serviceaccount" {
  yaml_body = var.alb_serviceaccount_yaml
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.alb_controller_chart_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  depends_on = [kubectl_manifest.alb_controller_serviceaccount]
}

# ---------------------------------------------------------------------------
# KEDA
# ---------------------------------------------------------------------------

resource "kubernetes_namespace" "keda" {
  metadata {
    name = "keda"
  }
}

resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.keda_chart_version
  namespace  = kubernetes_namespace.keda.metadata[0].name

  set {
    name  = "serviceAccount.name"
    value = "keda-operator"
  }

  set {
    name  = "podIdentity.aws.irsa.enabled"
    value = "true"
  }

  set {
    name  = "podIdentity.aws.irsa.roleArn"
    value = var.keda_role_arn
  }

  # Depende do ALB controller já estar pronto: seus pods respondem ao webhook
  # mutante de Service (mservice.elbv2.k8s.aws), que intercepta todo Service
  # criado no cluster, incluindo o do KEDA.
  depends_on = [kubernetes_namespace.keda, helm_release.aws_load_balancer_controller]
}
