# Use com: terraform plan -var-file="manual.tfvars"
#          terraform apply -var-file="manual.tfvars"
# Não é carregado automaticamente (só terraform.tfvars/*.auto.tfvars são).

aws_profile = "adanmartinez"

aws_region   = "us-east-2"
project_name = "toggle-master"
cluster_name = "eks-tc3-prod-001"
