/* 
IMPORTANT: Manual creation of the Run As Account is required after Azure Automation account is deployed.
*/

terraform {
  required_version = ">=1.8.0"
}



##Azure Automation Account (TF Managed)
/*
resource "azurerm_automation_account" "az_automation" {
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  name                = var.azure_automation_account_name
  sku_name            = "Basic"
  tags                = var.tags
}
*/

#Import Existing Automation Account (not TF managed)
data "azurerm_automation_account" "az_automation" {
  resource_group_name = var.resource_group_name
  name                = var.azure_automation_account_name
}

##Runbooks
//Runbook URL
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

//Runbook File

data "local_file" "example_file" {
  filename = "${path.module}/runbooks/Clear-HorizonSessions.ps1"
}
resource "azurerm_automation_runbook" "example_runbook" {
  name                    = "Clear-HorizonSessions"
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  log_verbose             = "true"
  log_progress            = "false"
  description             = "Clear Old Horizon"
  runbook_type            = "PowerShell"
  content                 = data.local_file.example_file.content
}

//Runbook Folder 
resource "azurerm_automation_runbook" "foreach_runbook" {
  for_each                = fileset(".", "${path.module}/dir/*.ps1")
  name                    = split(".", split("/", each.value)[3])[0]
  location                = var.resource_group_location
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  log_verbose             = "false"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = filemd5("${each.value}")
}


##Azure Automation Schedules
//Daily Schedule
resource "azurerm_automation_schedule" "aa_schedule_daily" {
  name                    = "Daily"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  frequency               = "Day"
  interval                = 1
  timezone                = "America/Los_Angeles"
  description             = "Run daily"
}

//Daily 9PM Schedule
resource "azurerm_automation_schedule" "aa_2100" {
  name                    = "Daily_9PM"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  frequency               = "Day"
  interval                = 1
  start_time              = "2024-05-15T00:00:00Z"
  timezone                = "America/Los_Angeles"
  description             = "Run daily"
}

//Daily 4AM Schedule
resource "azurerm_automation_schedule" "aa_0400" {
  name                    = "Daily_4AM"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  frequency               = "Day"
  interval                = 1
  start_time              = "2024-05-15T00:00:00Z"
  timezone                = "America/Los_Angeles"
  description             = "Run daily"
}


##Azure Automation Job Schedules
//Update Azure Modules Daily
resource "azurerm_automation_job_schedule" "aa_job_schedule_daily" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  schedule_name           = azurerm_automation_schedule.aa_schedule_daily.name
  runbook_name            = azurerm_automation_runbook.runbook_update_modules.name

  parameters = {
    resourcegroupname     = var.resource_group_name
    automationaccountname = var.azure_automation_account_name
    azuremoduleclass      = "az"
  }
}

#Daily at 9PM
resource "azurerm_automation_job_schedule" "aa_job_schedule_2100" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  schedule_name           = azurerm_automation_schedule.aa_2100.name
  runbook_name            = azurerm_automation_runbook.example_runbook.name
}

#Daily at 4AM
resource "azurerm_automation_job_schedule" "aa_job_schedule_0400" {
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  schedule_name           = azurerm_automation_schedule.aa_0400.name
  runbook_name            = azurerm_automation_runbook.example_runbook.name
}


##Azure Automation Modules for Runbooks
resource "azurerm_automation_module" "aa_module_azaccounts" {
  name                    = "Az.Accounts"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts"
  }
}

resource "azurerm_automation_module" "aa_module_azcompute" {
  name                    = "Az.Compute"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Compute"
  }
}

resource "azurerm_automation_module" "aa_module_azresources" {
  name                    = "Az.Resources"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Resources"
  }
}

resource "azurerm_automation_module" "aa_module_azmanagedserviceidentity" {
  name                    = "Az.ManagedServiceIdentity"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.ManagedServiceIdentity"
  }
}


##Azure Automation Credentials
resource "azurerm_automation_credential" "api_creds" {
  name                    = "api_creds"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  username                = "domain.net\\UserName"
  password                = var.api_pw
  description             = "Credential to access API"
}

##Azure Runbook variables
resource "azurerm_automation_variable_string" "domain_join_pw" {
  name                    = "var_domain_join_pw"
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  encrypted               = true
  value                   = var.domain_join_pw
}