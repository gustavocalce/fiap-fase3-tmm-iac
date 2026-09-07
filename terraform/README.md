# Como rodar este Terraform localmente

## 1. Pré-requisitos

- Terraform >= 1.10
- AWS CLI v2
- Acesso à conta AWS (account id atual é detectado automaticamente via `data.aws_caller_identity`)

## 2. Configurar credenciais AWS via chave de acesso

Evite login via SSO/`aws login`: o token expira em ~15min, tempo insuficiente para o `apply`
completo (EKS + RDS + ElastiCache podem levar mais de 15min). Use uma chave de acesso
estática (Access Key/Secret Key de um usuário IAM):

```powershell
aws configure --profile <nome-do-profile>
```

Vai pedir, em sequência (digite direto no terminal):
1. **AWS Access Key ID**
2. **AWS Secret Access Key**
3. **Default region name** → `us-east-2`
4. **Default output format** → `json` (ou vazio)

Teste:
```powershell
aws sts get-caller-identity --profile <nome-do-profile>
```

Se você já tiver rodado `aws login` (SSO) antes nesta mesma sessão de terminal, limpe as
variáveis de ambiente residuais — elas têm prioridade sobre `--profile` e podem estar
expiradas:
```powershell
Remove-Item Env:\AWS_ACCESS_KEY_ID, Env:\AWS_SECRET_ACCESS_KEY, Env:\AWS_SESSION_TOKEN, Env:\AWS_CREDENTIAL_EXPIRATION -ErrorAction SilentlyContinue
```

## 3. Inicializar

```powershell
cd terraform
terraform init
```

## 4. Plan / Apply

### Opção A — sem tfvars (usa os defaults de `variables.tf` + flag de profile)

```powershell
terraform plan  -var="aws_profile=<nome-do-profile>"
terraform apply -var="aws_profile=<nome-do-profile>"
```

### Opção B — com `manual.tfvars` (já vem com `aws_profile` preenchido)

```powershell
terraform plan  -var-file="manual.tfvars"
terraform apply -var-file="manual.tfvars"
```

Edite [manual.tfvars](manual.tfvars) se o nome do seu profile for diferente de `adanmartinez`.
Esse arquivo não é carregado automaticamente (só `terraform.tfvars`/`*.auto.tfvars` são) —
precisa sempre do `-var-file`.

### Opção C — fixar de vez (sem repetir flag)

Renomeie/crie `terraform.tfvars` com `aws_profile = "<nome-do-profile>"`. Esse arquivo É
carregado automaticamente pelo Terraform, então depois disso basta `terraform apply`.

## 5. Problemas já conhecidos deste projeto

- **Node group falha com "AMI not supported"**: já corrigido — `c7i-flex.large` exige
  `ami_type = "AL2023_x86_64_STANDARD"` (ver [modules/eks/main.tf](modules/eks/main.tf)).
- **RDS "Cannot find version"**: a versão do Postgres em `rds_engine_version` precisa
  existir na região; confira com:
  ```powershell
  aws rds describe-db-engine-versions --engine postgres --region us-east-2 --query "DBEngineVersions[].EngineVersion" --output table
  ```
- **KEDA falha por webhook do ALB sem endpoints**: já corrigido com `depends_on` explícito
  do Helm release do KEDA no do ALB controller.
- **`kubectl_manifest` trava ~10min e falha com "context deadline exceeded"**: os
  Deployments têm `wait_for_rollout = false` (ver
  [modules/k8s-manifests/main.tf](modules/k8s-manifests/main.tf)) porque os repositórios
  ECR são criados vazios — os pods ficam em `ImagePullBackOff` até você buildar e publicar
  as imagens (README principal, seções 5.4 em diante).
- **Apply falha no meio com "Failed to save state" / `errored.tfstate`**: normalmente por
  credencial expirada durante um apply longo. Recupere com:
  ```powershell
  terraform state push errored.tfstate
  # se der "Error acquiring the state lock":
  terraform force-unlock -force <LockID-do-erro>
  ```
  Depois rode `terraform apply` de novo — é idempotente, só cria o que falta.

## 6. Destruir tudo

```powershell
terraform destroy -var-file="manual.tfvars"
```
