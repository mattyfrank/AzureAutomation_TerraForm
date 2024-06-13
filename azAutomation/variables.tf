# Variables for main.tf file. These will get prompted at runtime or can be defined inline when running terraform. 
# Additionally they can be declared in the .tfvar file in the variables folder.

variable "env" {
  description = "Environment (prod, nonprod)"
  type        = string

  validation {
    condition     = contains(["prod", "nonprod"], var.env)
    error_message = "Valid values for var: env are (prod, nonprod)."
  }

  default = "nonprod"
}

# Resource Group
variable "resource_group_name" {
  description = "The Azure resource group name to contain resources."
  type        = string

  default = "rg-prod-mgmt" #"rg-mgmt-${var.env}-002"
}

variable "resource_group_location" {
  description = "The Azure resource group location."
  type        = string

  default = "westus2"
}

# Azure Automation
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string

  default = "aa-prod-westus2" #"aa-management-${var.env}-100"
}

variable "api_pw" {
  description = "Password for Horizon API account."
  type        = string
  sensitive   = true

  default = "Example-Creds123!"
}

variable "domain_join_pw" {
  description = "Password for Domain Join."
  type        = string
  sensitive   = true

  default = "Example-Creds123!"
}

variable "domain_join_upn" {
  description = "Password for Domain Join."
  type        = string
  sensitive   = true

  default = "ServiceAccount001"
}

# Networks
variable "network_resource_group_name" {
  description = "Resource group name for networking resources."
  type        = string
  
  default = "Network_RG"
}
variable "virtual_network_name" {
  description = "Name of Virtual Network (VNET)."
  type        = string

  default = "internal-network"
}

variable "hybrid_worker_subnet_id" {
  description = "Subnet ID for Hybrid Workers."
  type        = string

  default = ""
}

# Tags
variable "tags" {
  description = "Resource tags."
  type        = map(any)

  default = {
    environment = ""
    note        = ""
  }
}