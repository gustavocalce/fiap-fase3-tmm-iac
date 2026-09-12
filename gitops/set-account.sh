#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Substitui o Account ID antigo (fase 2) pelo account real da Fase 3 em toda a
# pasta gitops/. Corrige de uma vez: role-arn das ServiceAccounts, URI do ECR
# nas imagens (kustomization + deployment) e as URLs de SQS.
#
# Uso:
#   bash gitops/set-account.sh 123456789012      # informando o account
#   bash gitops/set-account.sh                    # autodetecta via AWS CLI
# -----------------------------------------------------------------------------
set -euo pipefail

OLD="570814275471"
NEW="${1:-}"

if [[ -z "$NEW" ]] && command -v aws >/dev/null 2>&1; then
  NEW="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
fi

if [[ ! "$NEW" =~ ^[0-9]{12}$ ]]; then
  echo "ERRO: account ID inválido ('${NEW:-vazio}')."
  echo "Uso: bash gitops/set-account.sh <ACCOUNT_ID_12_DIGITOS>"
  echo "     (ou configure o AWS CLI para autodetectar via 'aws sts get-caller-identity')"
  exit 1
fi

if [[ "$NEW" == "$OLD" ]]; then
  echo "O account informado é o mesmo antigo ($OLD) — nada a fazer."
  exit 0
fi

count=0
while IFS= read -r f; do
  sed -i "s/${OLD}/${NEW}/g" "$f"
  echo "  atualizado: $f"
  count=$((count+1))
done < <(grep -rl "$OLD" gitops/ 2>/dev/null || true)

if [[ $count -eq 0 ]]; then
  echo "Nenhuma ocorrência de $OLD em gitops/ (já substituído?)."
else
  echo "Feito: $OLD -> $NEW em $count arquivo(s)."
  echo "Valide com: kubectl kustomize gitops/apps/flag-service | grep -E 'image:|role-arn'"
fi
