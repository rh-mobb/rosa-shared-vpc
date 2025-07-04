# rosa-shared-vpc

This terraform management file will generate a reference Private ROSA HCP cluster in shared vpc architecture.
Includes:
* Cluster owner account
* Account roles
* OIDC Config and Provider
* Operator roles
* Cluster
* Shared VPC Assume Roles
  * Route53 assume role
  * Attached to
    * Installer Account Role
    * Ingress Operator Role
    * Control Plane Operator Role
* VPCE assume role
  * Attached to
    * Installer Account Role
    * Control Plane Operator Role
   
# Usage

## Planning

- Full usage with command line variable

        $ terraform plan -out rosa.tfplan \
            -var token="your OpenShift Cluster Manager API Token"

## Apply
    
        $ terraform apply rosa.tfplan

