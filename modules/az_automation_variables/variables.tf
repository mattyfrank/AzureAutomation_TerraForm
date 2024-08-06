/*
 __     __         _       _     _           
 \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
                                             
# Variables for main.tf file. These will get prompted at runtime or can be defined inline when running terraform. 
*/

variable "env" {
  description = "Environment (prod, nonprod)"
  type        = string
  validation {
    condition     = contains(["prod", "nonprod"], var.env)
    error_message = "Valid values for var: env are (prod, nonprod)."
  }
}

# Resource Group Name
variable "resource_group_name" {
  description = "The Azure resource group name to contain resources."
  type        = string
}

# Azure Automation Name
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
}

# Azure Automation Variables
variable "aa_testVar_value" {
  description = "Test Variable"
  type        = string
  sensitive   = true
}