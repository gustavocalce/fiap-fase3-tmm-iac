#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Teste local (Nível 2) do ArgoCD/GitOps — sobe um cluster kind, instala o
# ArgoCD e aplica a root-app (App of Apps). Serve para validar o fluxo GitOps
# (UI gerenciando os 5 serviços, OutOfSync -> Sync) SEM precisar da AWS.
#
# LIMITAÇÃO ESPERADA: os pods NÃO ficam Healthy num kind, porque dependem de
# ECR, Secrets Store CSI, IRSA e KEDA (só existem no EKS real). O que se
# demonstra aqui é o ArgoCD detectando o Git e sincronizando os manifests.
#
# IMPORTANTE: o ArgoCD lê do GitHub (repoURL nas Applications), NÃO do seu
# disco. Comite e dê push do gitops/ no main ANTES de rodar isto.
#
# Uso:   bash gitops/test-local.sh
#        bash gitops/test-local.sh --clean   # remove o cluster kind
# -----------------------------------------------------------------------------
set -euo pipefail

CLUSTER_NAME="argocd-test"
ARGOCD_NS="argocd"
REPO_EXPECTED="gitops/bootstrap/root-app.yaml"

red()  { printf "\033[31m%s\033[0m\n" "$1"; }
grn()  { printf "\033[32m%s\033[0m\n" "$1"; }
ylw()  { printf "\033[33m%s\033[0m\n" "$1"; }

if [[ "${1:-}" == "--clean" ]]; then
  kind delete cluster --name "$CLUSTER_NAME"
  grn "Cluster '$CLUSTER_NAME' removido."
  exit 0
fi

# --- 1. Pré-requisitos --------------------------------------------------------
missing=0
for t in docker kind helm kubectl git; do
  if ! command -v "$t" >/dev/null 2>&1; then
    red "FALTANDO: $t"
    missing=1
  fi
done
if [[ $missing -eq 1 ]]; then
  cat <<'EOF'

Instale o que falta (Windows, num terminal como admin):
  winget install Kubernetes.kind
  winget install Helm.Helm
  # Docker Desktop: https://www.docker.com/products/docker-desktop/  (e ABRA ele)

Ou via Chocolatey:
  choco install kind kubernetes-helm -y
EOF
  exit 1
fi

if ! docker ps >/dev/null 2>&1; then
  red "O daemon do Docker não está rodando. Abra o Docker Desktop e espere ficar 'Running'."
  exit 1
fi

# --- 2. Sanidade: código precisa estar no GitHub ------------------------------
if [[ ! -f "$REPO_EXPECTED" ]]; then
  red "Rode este script a partir da RAIZ do repo (não achei $REPO_EXPECTED)."
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if ! git diff --quiet -- gitops/ || ! git diff --cached --quiet -- gitops/; then
  ylw "AVISO: há mudanças não commitadas em gitops/. O ArgoCD lê do GitHub,"
  ylw "       então comite e faça push antes que o Sync reflita suas mudanças:"
  ylw "         git add gitops/ .github/ && git commit -m 'gitops' && git push origin $BRANCH"
  echo
fi

# --- 3. Cluster kind ----------------------------------------------------------
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  grn "Cluster kind '$CLUSTER_NAME' já existe, reutilizando."
else
  grn "Criando cluster kind '$CLUSTER_NAME'..."
  kind create cluster --name "$CLUSTER_NAME"
fi
kubectl config use-context "kind-$CLUSTER_NAME" >/dev/null

# --- 4. ArgoCD via Helm -------------------------------------------------------
grn "Instalando/atualizando ArgoCD no namespace '$ARGOCD_NS'..."
helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null
helm upgrade --install argocd argo/argo-cd \
  -n "$ARGOCD_NS" --create-namespace --wait --timeout 10m

# --- 5. Root-app (App of Apps) ------------------------------------------------
grn "Aplicando a root-app (ela cria as 5 Applications filhas)..."
kubectl apply -f gitops/bootstrap/root-app.yaml

# --- 6. Info de acesso --------------------------------------------------------
echo
grn "==================== ArgoCD pronto ===================="
PW="$(kubectl -n "$ARGOCD_NS" get secret argocd-initial-admin-secret \
      -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"
echo "Usuário: admin"
echo "Senha:   ${PW:-<ainda gerando; rode de novo em alguns segundos>}"
echo
echo "Abra a UI (deixe este comando rodando em outro terminal):"
echo "  kubectl -n $ARGOCD_NS port-forward svc/argocd-server 8080:443"
echo "  -> https://localhost:8080  (aceite o certificado self-signed)"
echo
echo "Acompanhar pelo terminal:"
echo "  kubectl -n $ARGOCD_NS get applications"
echo
ylw "Lembrete: os pods vão ficar em ImagePullBackOff/erro de CSI (sem AWS)."
ylw "Isso é esperado no kind — o objetivo aqui é ver o ArgoCD sincronizando o Git."
echo
echo "Para derrubar tudo:  bash gitops/test-local.sh --clean"
