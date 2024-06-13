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

variable "hybrid_worker_subnet_id" {
  description = "Subnet ID for Hybrid Workers."
  type        = string
}

variable "domain_join_pw" {
  description = "Password for Domain Join."
  type        = string
  sensitive   = true
}

variable "domain_join_upn" {
  description = "Password for Domain Join."
  type        = string
  sensitive   = true
}

# Tags
variable "tags" {
  description = "Resource tags."
  type        = map(any)
}