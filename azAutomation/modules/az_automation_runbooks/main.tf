/*
    _                        _       _                  _   _            ___           _              _       
   /_\   ____  _ _ _ ___    /_\ _  _| |_ ___ _ __  __ _| |_(_)___ _ _   | _ \_  _ _ _ | |__  ___  ___| |__ ___
  / _ \ |_ / || | '_/ -_)  / _ \ || |  _/ _ \ '  \/ _` |  _| / _ \ ' \  |   / || | ' \| '_ \/ _ \/ _ \ / /(_-<
 /_/ \_\/__|\_,_|_| \___| /_/ \_\_,_|\__\___/_|_|_\__,_|\__|_\___/_||_| |_|_\\_,_|_||_|_.__/\___/\___/_\_\/__/


  Module: az_automation_runbooks
  Description: This module creates Azure Automation Runbooks in an Azure Automation Account.

  Notes: 
  - The runbooks are created from the files in the runbooks folder.
  - The runbooks are named after the file name.
  - The RunBook Schedule and RunOn are not configured in this module. 
  - The Runbook tags are {HybirdWorker=True} -or- {HybridWorker=False}.
*/

## Runbook URL
resource "azurerm_automation_runbook" "runbook_update_modules" {
  name                    = "Update-AutomationAzureModulesForAccount"
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  log_verbose             = "false"
  log_progress            = "true"
  description             = "Updates Azure PowerShell modules imported into an Azure Automation account."
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/microsoft/AzureAutomation-Account-Modules-Update/master/Update-AutomationAzureModulesForAccount.ps1"
  }
}

## Runbook Folder. Runbooks are named after the file name.
resource "azurerm_automation_runbook" "runbooks" {
  for_each                = fileset("./runbooks/", "*.ps1")
  name                    = split(".", each.key)[0]
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  log_verbose             = "false"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = file(format("%s%s", "./runbooks/", each.key))
  //Configure the tags for each runbook 
  # tags={HybridWorker=True}
}


## Runbook File
/*
data "local_file" "file_runbook_name" {
  filename = "${path.module}/runbooks/runbook_file_name.ps1"
}
resource "azurerm_automation_runbook" "example_runbook" {
  name                    = "Example_Runbook"
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  log_verbose             = "false"
  log_progress            = "true"
  description             = "Example of a Runbook File"
  runbook_type            = "PowerShell"
  content                 = data.local_file.file_runbook_name.content
}
*/