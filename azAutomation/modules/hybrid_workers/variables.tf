/* 
Variables for main.tf file in automation_account module. These get passed in from top main.tf calling the module.
*/

variable "env" {
  description = "Environment (prod, nonprod)"
  type        = string

  validation {
    condition     = contains(["prod", "nonprod"], var.env)
    error_message = "Valid values for var: env are (prod, nonprod)."
  }
}
# Tags
variable "tags" {
  description = "Resource tags."
  type        = map(string)
}

# Resource Group
variable "resource_group_name" {
  description = "The Azure resource group name to contain resources."
  type        = string
}
variable "resource_group_location" {
  description = "The Azure resource group location."
  type        = string
}

# Azure Automation Account
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
}

# Networking
variable "network_resource_group_name" {
  description = "Resource group name for networking resources."
  type        = string
}
variable "virtual_network_name" {
  description = "Name of Virtual Network (VNET)."
  type        = string
}
variable "hybrid_subnet_name" {
  description = "Name of subnet for Hybrid Workers."
  type        = string
}

# Domain Join
variable "domain_join_pw" {
  description = "Password for Domain Join."
  type        = string
  sensitive   = true
}

variable "domain_join_upn" {
  description = "UPN for Domain Join."
  type        = string
  sensitive   = true
}

variable "local_admin_pw" {
  description = "Local Admin Password."
  type        = string
  sensitive   = true
}

variable "local_admin_user" {
  description = "Local Admin UserName."
  type        = string
  sensitive   = true
}

# Hybrid Worker Group
variable "hybrid_worker_group_name" {
  description = "Name of Hybrid Worker Group."
  type        = string
}