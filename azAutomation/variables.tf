/*
 __     __         _       _     _           
 \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/

# Variables for main.tf file. These will get prompted at runtime or can be defined inline when running terraform. 
# Additionally they can be declared in the .tfvar file in the variables folder.
# These variables are used to define the resources in the main.tf file.
*/

variable "env" {
  description = "Environment (prod, nonprod)"
  type        = string
  validation {
    condition     = contains(["prod", "nonprod"], var.env)
    error_message = "Valid values for var: env are (prod, nonprod)."
  }

  //Force NonProd
  default = "nonprod"
}

# Tags
variable "tags" {
  description = "Resource tags."
  type        = map(string)
}

# Networks
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

# Resource Group
variable "resource_group_name" {
  description = "The Azure resource group name to contain resources."
  type        = string
}

variable "resource_group_location" {
  description = "The Azure resource group location."
  type        = string
}

# Azure Automation
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
}

#Hybrid Worker Group
variable "hybrid_worker_group_name" {
  description = "Hybrid Worker Group Name."
  type        = string
}

# Azure Automation Modules
variable "automation_powershell_5_modules" {
  description = "Map of Automation PowerShell 5.1 Modules"
  type        = map(string)
  default     = {}
}
variable "automation_powershell_7_modules" {
  description = "Map of Automation PowerShell 7.2 Modules"
  type        = map(string)
  default     = {}
}

# Azure Automation Schedules
variable "automation_schedules" {
  description = "Map of Schedules"
  type = map(object({
    name        = string
    start_time  = string
    description = string
    frequency   = string
    week_days   = optional(list(string))
    month_days  = optional(list(number))
  }))
}

# Azure Automation Scheduled Jobs
variable "automation_job_schedules" {
  description = "Map of Job Schedules"
  type = map(object({
    schedule_name = string
    runbook_name  = string
    hybrid_worker = bool
  }))
}

# Azure Automation Credentials
variable "aa_hasa_pw" {
  description = "Horizon API Password"
  type        = string
  sensitive   = true
}

# Azure Automation Variables
variable "aa_testVar_value" {
  description = "Test Variable"
  type        = string
  sensitive   = true
}

#VMSS Variables
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