/*
     _                             _         _                        _   _               ____       _              _       _          _       _       _         
    / \    _____   _ _ __ ___     / \  _   _| |_ ___  _ __ ___   __ _| |_(_) ___  _ __   / ___|  ___| |__   ___  __| |_   _| | ___  __| |     | | ___ | |__  ___ 
   / _ \  |_  / | | | '__/ _ \   / _ \| | | | __/ _ \| '_ ` _ \ / _` | __| |/ _ \| '_ \  \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \/ _` |  _  | |/ _ \| '_ \/ __|
  / ___ \  / /| |_| | | |  __/  / ___ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | |  ___) | (__| | | |  __/ (_| | |_| | |  __/ (_| | | |_| | (_) | |_) \__ \
 /_/   \_\/___|\__,_|_|  \___| /_/   \_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_| |____/ \___|_| |_|\___|\__,_|\__,_|_|\___|\__,_|  \___/ \___/|_.__/|___/
                                                                                                                                                                 
  Module: az_automation_jobs
  Description: This module associates Azure Automation Runbooks with a Schedule in an Azure Automation Account.
  Notes:
    - Automation Jobs are Assigning the Runbooks to a Schedule.
    - Jobs will follow a Hourly, Daily, Weekly, or Monthly Schedule.
*/

## Update Azure Modules Daily
resource "azurerm_automation_job_schedule" "aa_module_schedule" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  schedule_name           = var.automation_schedules["aa_2100"].name
  runbook_name            = var.automation_runbook_update_modules.name

  parameters = {
    resourcegroupname     = var.resource_group_name
    automationaccountname = var.azure_automation_account_name
    azuremoduleclass      = "az"
  }
}

## Scheduled Jobs
#match the schedule name with the schedule name in the automation_schedules variable
resource "azurerm_automation_job_schedule" "aa_job_schedules" {
  for_each                = var.automation_job_schedules
  schedule_name           = var.automation_schedules["${each.value.schedule_name}"].name
  runbook_name            = var.automation_runbooks["${each.value.runbook_name}"].name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  run_on                  = try(each.value.hybrid_worker == true ? "${var.hybrid_worker_group_name}" : null)
}
