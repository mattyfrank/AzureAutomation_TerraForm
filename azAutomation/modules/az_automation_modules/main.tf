/*
     _                             _         _                        _   _               __  __           _       _           
    / \    _____   _ _ __ ___     / \  _   _| |_ ___  _ __ ___   __ _| |_(_) ___  _ __   |  \/  | ___   __| |_   _| | ___  ___ 
   / _ \  |_  / | | | '__/ _ \   / _ \| | | | __/ _ \| '_ ` _ \ / _` | __| |/ _ \| '_ \  | |\/| |/ _ \ / _` | | | | |/ _ \/ __|
  / ___ \  / /| |_| | | |  __/  / ___ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | | | |  | | (_) | (_| | |_| | |  __/\__ \
 /_/   \_\/___|\__,_|_|  \___| /_/   \_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_| |_|  |_|\___/ \__,_|\__,_|_|\___||___/
                                                                                                                               
Azure Automation RunTime Modules
- This module will install PowerShell Modules in an Azure Automation Account.
- Currently not in use as RunTime Modules are still in Preview.
*/

resource "azurerm_automation_module" "aa_posh5_modules" {
  for_each                = var.automation_powershell_5_modules
  name                    = each.value
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/${each.value}"
  }
}
resource "azurerm_automation_powershell72_module" "aa_posh7_modules" {
  for_each              = var.automation_powershell_7_modules
  name                  = each.value
  automation_account_id = var.azure_automation_account_id
  module_link {
    uri = each.value
  }
}