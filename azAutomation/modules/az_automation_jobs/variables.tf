/*
 __     __         _       _     _           
 \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
                                              
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

# Azure Automation
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
}

# Azure Automation Schedule Jobs
variable "automation_job_schedules" {
  description = "Map of Job Schedules"
  type = map(object({
    schedule_name = string
    runbook_name  = string
    hybrid_worker = bool
  }))
}

#Azure Automation Runbooks
variable "automation_runbooks" {
  description = "Map of Runbooks"
  type        = map(string)
}
variable "automation_runbook_update_modules" {
  description = "Runbook to update Azure Modules"
  type        = map(string)
}

# Azure Automation Schedules
variable "automation_schedules" {
  type = map(object({
    name        = string
    start_time  = string
    description = string
    frequency   = string
    week_days   = list(string)
    month_days  = list(string)
  }))
}

# Hybrid Worker Group
variable "hybrid_worker_group_name" {
  description = "The name of the Hybrid Worker Group."
  type        = string
}