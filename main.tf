data "aws_partition" "current" {} # Obtém a partição AWS atual (ex: aws, aws-cn)
data "aws_region" "current" {} # Obtém a região AWS atual

provider "aws" { # Configura o provider AWS para o proprietário do cluster
  alias = "cluster-owner"
  region                   = data.aws_region.current.name
}

locals {
  account_role_prefix          = "rosa-acc" # Prefixo para roles por conta AWS
  operator_role_prefix         = "rosa-op" # Prefixo para roles por cluster
  ingress_hosted_zone_id = "Z065940228IEN7CTWQ7TB" # 
  internal_hosted_zone_id =  "Z00999482Q8OXGKZWCR0G" # rosa.hypershift.local
  shared_vpc_roles_arns = { # ARNs das roles do VPC compartilhado
    "route53" : "arn:aws:iam::837740385180:role/openshift_hcp_shared_vpc_route_53_credentials_role", 
    "vpce" : "arn:aws:iam::837740385180:role/openshift_hcp_shared_vpc_vpc_endpoint_credentials_role"
  }
}

provider "rhcs" {
  token = var.token
}

##############################################################
# Módulo para criação de IAM roles e policies por conta AWS
##############################################################
module "account_iam_resources" {
  source = "git::https://github.com/terraform-redhat/terraform-rhcs-rosa-hcp.git//modules/account-iam-resources?ref=shared-vpc"
  providers = {
    aws = aws.cluster-owner
  }

  account_role_prefix        = local.account_role_prefix
  create_shared_vpc_policies = true
  shared_vpc_roles           = local.shared_vpc_roles_arns
}

############################
# Módulo para configuração do provedor OIDC
############################
module "oidc_config_and_provider" {
  source = "git::https://github.com/terraform-redhat/terraform-rhcs-rosa-hcp.git//modules/oidc-config-and-provider?ref=shared-vpc"
  providers = {
    aws = aws.cluster-owner
  }

  managed = true
}

############################
# Módulo para criação das roles do operador
############################
module "operator_roles" {
  source = "git::https://github.com/terraform-redhat/terraform-rhcs-rosa-hcp.git//modules/operator-roles?ref=shared-vpc"
  providers = {
    aws = aws.cluster-owner
  }

  operator_role_prefix       = local.operator_role_prefix
  path                       = module.account_iam_resources.path
  oidc_endpoint_url          = module.oidc_config_and_provider.oidc_endpoint_url
  create_shared_vpc_policies = false
  shared_vpc_roles           = local.shared_vpc_roles_arns
}


resource "rhcs_dns_domain" "dns_domain" { # Recurso para domínio DNS do cluster HCP
  cluster_arch = "hcp"
}

############################
# Módulo para criação do cluster ROSA STS
############################
module "rosa_cluster_hcp" {
  source = "git::https://github.com/terraform-redhat/terraform-rhcs-rosa-hcp.git//modules/rosa-cluster-hcp?ref=shared-vpc"

  cluster_name               = var.cluster_name
  openshift_version          = var.openshift_version
  version_channel_group      = var.version_channel_group
  machine_cidr               = "10.0.0.0/16"
  aws_subnet_ids             = ["subnet-0f0b3f7ac35900702", "subnet-0d170397e6bc63468"]
  replicas                   = 2
  private                    = true
  aws_billing_account_id     = var.aws_billing_account_id

  // Configuração STS
  oidc_config_id       = module.oidc_config_and_provider.oidc_config_id
  account_role_prefix  = module.account_iam_resources.account_role_prefix
  ec2_metadata_http_tokens   = "required"
  operator_role_prefix = module.operator_roles.operator_role_prefix
  shared_vpc = {
    ingress_private_hosted_zone_id                = local.ingress_hosted_zone_id
    internal_communication_private_hosted_zone_id = local.internal_hosted_zone_id
    route53_role_arn                              = local.shared_vpc_roles_arns.route53
    vpce_role_arn                                 = local.shared_vpc_roles_arns.vpce
  }
  base_dns_domain                   = "3svr.p3.openshiftapps.com"
  aws_additional_allowed_principals = [local.shared_vpc_roles_arns.route53, local.shared_vpc_roles_arns.vpce]
}
