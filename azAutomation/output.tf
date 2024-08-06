/*
   ___        _               _   
  / _ \ _   _| |_ _ __  _   _| |_ 
 | | | | | | | __| '_ \| | | | __|
 | |_| | |_| | |_| |_) | |_| | |_ 
  \___/ \__,_|\__| .__/ \__,_|\__|
                 |_|              
-----------------------------------
  - Notes:
    -Output from MAIN Module Defined in main.tf
    -Output from CHILD Modules will use the name of the Output from the Module.
*/


output "resource_group_name" {
  value       = data.azurerm_resource_group.rg.name
  description = "Resource Group Name"
}

output "azure_automation_account_name" {
  value       = var.azure_automation_account_name
  description = "Automation Account Name"
}

output "azure_automation_runbooks" {
  value = module.az_automation_runbooks.azure_automation_runbooks
}

output "azure_automation_schedules" {
  value = module.az_automation_schedules.azure_automation_schedules
}

output "automation_jobs" {
  #value = module.az_automation_jobs.azure_automation_jobs
  value = values(var.automation_job_schedules)[*].schedule_name
}