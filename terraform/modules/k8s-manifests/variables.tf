variable "k8s_path" {
  description = "Caminho absoluto para a pasta K8s/ do repositório"
  type        = string
}

variable "account_id" {
  description = "Conta AWS ativa; substitui o account id antigo (570814275471) hardcoded nos manifests"
  type        = string
}

variable "old_account_id" {
  description = "Account id originalmente hardcoded nos manifests K8s/AWS deste repositório"
  type        = string
  default     = "570814275471"
}
