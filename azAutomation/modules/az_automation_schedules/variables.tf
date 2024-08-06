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

# Azure Automation
variable "azure_automation_account_name" {
  description = "Specifies the name of the azure automation account."
  type        = string
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