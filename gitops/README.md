# GitOps (ArgoCD) — Fase 3 TMM

Fonte da verdade dos 5 workloads. O ArgoCD (`selfHeal: true`) reconcilia o
cluster com o que está aqui no Git. O Terraform deixa de ser dono dos manifests
dos workloads (ver §1 do `HANDOFF-argocd-gitops.md`).

## Estrutura

```
gitops/
  bootstrap/
    root-app.yaml            # App of Apps — aplica só este
    apps/                    # 1 Application por serviço
  apps/
    <service>/               # manifests + kustomization.yaml
```

## Pré-requisito: substituir o Account ID

Os manifests foram copiados verbatim da pasta `K8s/` e ainda carregam o account
ID antigo `570814275471` (role-arn das ServiceAccounts, URI do ECR nas imagens e
URLs de SQS). Antes do bootstrap, rode o script (pegue o account real com a
pessoa do IaC):

```bash
bash gitops/set-account.sh 123456789012   # informando o account
bash gitops/set-account.sh                 # ou autodetecta via AWS CLI
```

Isso corrige tudo de uma vez: annotations das SAs, URI das imagens e as URLs de
SQS. O tag da imagem continua sendo gerenciado à parte (bloco `images:`).

## Bootstrap do ArgoCD

Com o kubeconfig apontando pro cluster certo (confira `kubectl config
current-context`), rode o script versionado — ele instala o ArgoCD via Helm
(versão pinada) e aplica a root-app:

```bash
bash gitops/install-argocd.sh
```

Ele imprime a senha do admin e o comando de port-forward ao final. Manualmente,
o equivalente é:

```bash
helm install argocd argo/argo-cd -n argocd --create-namespace --version 7.7.11
kubectl apply -f gitops/bootstrap/root-app.yaml
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8080:443   # https://localhost:8080
```

Para testar sem AWS (cluster kind local), use `bash gitops/test-local.sh`.

## Validar localmente antes de commitar

```bash
kubectl kustomize gitops/apps/<service>
```

## Atualizar a versão de um serviço (contrato com o pipeline)

O pipeline chama o workflow reutilizável `.github/workflows/gitops-bump.yaml`
(`workflow_call`) passando `service` e `image_tag`. Ele roda:

```bash
cd gitops/apps/<service>
kustomize edit set image <ECR>/<service>:<SHA>
git commit -am "deploy <service> <SHA>" && git push
```

O ArgoCD detecta o commit e sincroniza. O ECR é **IMMUTABLE**: a tag TEM que ser
o SHA do commit (não reusar `1.0.x`). Para demo instantânea, configure um webhook
GitHub → ArgoCD (o polling padrão leva até 3 min) ou clique **Sync** na UI.

## Notas

- **analytics-service**: sem ingress; inclui `scaledobject.yaml` +
  `keda-trigger-auth.yaml`. A Application tem `ignoreDifferences` para o KEDA não
  deixar o ScaledObject `OutOfSync` para sempre (o KEDA muta `/spec/triggers` e
  `/status`).
- Os demais serviços seguem o mesmo padrão, variando só porta e paths do ingress.
