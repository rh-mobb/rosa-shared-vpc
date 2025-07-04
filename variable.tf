variable "cluster_name" {
  description = "Nome do cluster ROSA"
  type        = string
  default = "rosa"
}

variable "openshift_version" {
  description = "Versão do OpenShift a ser usada no cluster"
  type        = string
  default = "4.18.15"
}

variable "version_channel_group" {
  description = "Grupo de canal da versão do OpenShift (ex: stable, candidate)"
  type        = string
  default = "stable"
}

variable "aws_billing_account_id" {
  description = "ID da conta AWS para faturamento"
  type        = string
  default = "326067279389"
}

variable "token" {
  type      = string
  sensitive = true
}

variable "url" {
  type        = string
  description = "Provide OCM environment by setting a value to url"
  default     = "https://api.openshift.com"
}

