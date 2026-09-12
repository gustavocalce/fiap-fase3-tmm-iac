#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Instala o ArgoCD no cluster apontado pelo kubeconfig ATUAL e aplica a
# root-app (App of Apps). Versionado para atender ao "se não está no código,
# não existe" — a instalação do ArgoCD deixa de ser um passo manual.
#
# Pré-requisitos: helm + kubectl, e o kubeconfig apontando pro cluster certo
# (EKS real ou kind). Confira o contexto antes de rodar.
#
# Uso:  bash gitops/install-argocd.sh
# -----------------------------------------------------------------------------
set -euo pipefail

ARGOCD_NS="argocd"
CHART_VERSION="7.7.11"   # linha 7.7.x (Helm chart argo/argo-cd)

for t in helm kubectl; do
  command -v "$t" >/dev/null 2>&1 || { echo "FALTANDO: $t"; exit 1; }
done

CTX="$(kubectl config current-context 2>/dev/null || echo '?')"
echo "Instalando ArgoCD no contexto: $CTX"
echo "(Ctrl+C em 5s se o contexto estiver errado)"; sleep 5

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  -n "$ARGOCD_NS" --create-namespace --version "$CHART_VERSION" \
  --wait --timeout 10m

echo "Aplicando a root-app (App of Apps)..."
kubectl apply -f gitops/bootstrap/root-app.yaml

echo
echo "==================== ArgoCD pronto ===================="
PW="$(kubectl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret \
      -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"
echo "Usuário: admin"
echo "Senha:   ${PW:-<gerando; rode de novo em alguns segundos>}"
echo
echo "UI:  kubectl -n $ARGOCD_NS port-forward svc/argocd-server 8080:443"
echo "     -> https://localhost:8080"
echo "Apps: kubectl -n $ARGOCD_NS get applications"
