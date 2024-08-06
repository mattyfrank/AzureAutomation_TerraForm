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
# Azure Automation
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
}
variable "azure_automation_account_id" {
  description = "Specifies the id of the azure automation account."
  type        = string
}
# Modules
variable "automation_powershell_5_modules" {
  description = "Map of Automation PowerShell 5.1 Modules"
  type        = map(string)
}
variable "automation_powershell_7_modules" {
  description = "Map of Automation PowerShell 7.2 Modules"
  type        = map(string)
}