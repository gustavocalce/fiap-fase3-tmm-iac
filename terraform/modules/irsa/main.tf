locals {
  # role_name => { namespace, service_account }
  irsa_service_accounts = {
    "auth-service-secrets-role"          = { namespace = "auth-service", sa = "auth-service" }
    "flag-service-secrets-role"          = { namespace = "flag-service", sa = "flag-service" }
    "targeting-service-secrets-role"     = { namespace = "targeting-service", sa = "targeting-service" }
    "evaluation-service-secrets-role"    = { namespace = "evaluation-service", sa = "evaluation-service" }
    "analytics-service-role"             = { namespace = "analytics-service", sa = "analytics-service" }
    "aws-load-balancer-controller-role"  = { namespace = "kube-system", sa = "aws-load-balancer-controller" }
    "keda-operator-role"                 = { namespace = "keda", sa = "keda-operator" }
  }
}

data "aws_iam_policy_document" "irsa_trust" {
  for_each = local.irsa_service_accounts

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${each.value.namespace}:${each.value.sa}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = local.irsa_service_accounts

  name               = each.key
  assume_role_policy = data.aws_iam_policy_document.irsa_trust[each.key].json

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Policies específicas de cada serviço
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "auth_service_secrets" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      var.auth_database_url_secret_arn,
      var.auth_master_key_secret_arn,
    ]
  }
}

resource "aws_iam_policy" "auth_service_secrets" {
  name   = "auth-service-secrets-policy"
  policy = data.aws_iam_policy_document.auth_service_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "auth_service_secrets" {
  role       = aws_iam_role.this["auth-service-secrets-role"].name
  policy_arn = aws_iam_policy.auth_service_secrets.arn
}

data "aws_iam_policy_document" "flag_service_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.flag_database_url_secret_arn]
  }
}

resource "aws_iam_policy" "flag_service_secrets" {
  name   = "flag-service-secrets-policy"
  policy = data.aws_iam_policy_document.flag_service_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "flag_service_secrets" {
  role       = aws_iam_role.this["flag-service-secrets-role"].name
  policy_arn = aws_iam_policy.flag_service_secrets.arn
}

data "aws_iam_policy_document" "targeting_service_secrets" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [var.targeting_database_url_secret_arn]
  }
}

resource "aws_iam_policy" "targeting_service_secrets" {
  name   = "targeting-service-secrets-policy"
  policy = data.aws_iam_policy_document.targeting_service_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "targeting_service_secrets" {
  role       = aws_iam_role.this["targeting-service-secrets-role"].name
  policy_arn = aws_iam_policy.targeting_service_secrets.arn
}

data "aws_iam_policy_document" "evaluation_service" {
  statement {
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      var.evaluation_service_api_key_secret_arn,
      var.evaluation_redis_url_secret_arn,
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "evaluation_service" {
  name   = "evaluation-service-policy"
  policy = data.aws_iam_policy_document.evaluation_service.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "evaluation_service" {
  role       = aws_iam_role.this["evaluation-service-secrets-role"].name
  policy_arn = aws_iam_policy.evaluation_service.arn
}

data "aws_iam_policy_document" "analytics_service" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.sqs_queue_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_table_arn]
  }
}

resource "aws_iam_policy" "analytics_service" {
  name   = "analytics-service-policy"
  policy = data.aws_iam_policy_document.analytics_service.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "analytics_service" {
  role       = aws_iam_role.this["analytics-service-role"].name
  policy_arn = aws_iam_policy.analytics_service.arn
}

# KEDA precisa apenas de GetQueueAttributes para calcular o autoscaling
data "aws_iam_policy_document" "keda" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:GetQueueAttributes"]
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "keda" {
  name   = "keda-sqs-policy"
  policy = data.aws_iam_policy_document.keda.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "keda" {
  role       = aws_iam_role.this["keda-operator-role"].name
  policy_arn = aws_iam_policy.keda.arn
}

# ALB controller: policy genérica e extensa, reaproveitada diretamente do
# arquivo já existente no repositório (AWS/alb-controller/iam-policy.json)
resource "aws_iam_policy" "alb_controller" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = var.alb_iam_policy_json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.this["aws-load-balancer-controller-role"].name
  policy_arn = aws_iam_policy.alb_controller.arn
}
