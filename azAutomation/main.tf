/* 
Infrastructure as code for Azure Automation. This was designed to be run from GitLab CICD
with variables being injected at run time. 

Requires Managed Identity to be created and assigned to the Azure Automation account.

Terraform backend is hosted on the GitLab project.

Pipeline environmental variables:
	
Azure_Managed_ID
Azure_Managed_PW
Azure_Subscription_ID
Azure_Tenant_ID

*/

terraform {
  # Use GitLab hosted backend for state files
  #backend "http" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.103.0"
    }
  }
}

#Azure Resource Manager Provider
provider "azurerm" {
  features {}
}


## Resource Group

//Manage ResourceGroup with TF
/*
# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name #"aa-management-${var.env}-100"
#   location = var.resource_group_location
#   tags     = var.tags
# }
*/

//Import Existing ResourceGroup (not TF managed)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Virtual Network
data "azurerm_resource_group" "rg_network" {
  name = var.network_resource_group_name
}
data "azurerm_subnet" "subnet_mgmt" {
  name                 = "subnet-mgmt-01"
  resource_group_name  = var.network_resource_group_name
  virtual_network_name = var.virtual_network_name
}

# Module: Azure Automation Account and RunBooks
module "az_automation" {
  source                        = "./modules/az_automation"
  env                           = var.env
  resource_group_location       = data.azurerm_resource_group.rg.location #var.resource_group_location
  resource_group_name           = data.azurerm_resource_group.rg.name     #var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name       #"aa-management-${var.env}-100"
  api_pw                        = var.api_pw                              #from CICD variables
  domain_join_pw                = var.domain_join_pw                      #from CICD variables
  tags                          = var.tags
}


module "az_hybridworker" {
  source                        = "./modules/hybrid_worker"
  env                           = var.env
  resource_group_location       = data.azurerm_resource_group.rg.location #var.resource_group_location
  resource_group_name           = data.azurerm_resource_group.rg.name     #var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name       #"aa-management-${var.env}-100"
  hybrid_worker_subnet_id       = data.azurerm_subnet.subnet_mgmt.id
  domain_join_pw                = var.domain_join_pw                      #from CICD variables
  domain_join_upn               = var.domain_join_upn                     #from CICD variables
  tags                          = var.tags
}