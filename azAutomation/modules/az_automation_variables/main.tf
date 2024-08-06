/*
     _                             _         _                        _   _              __     __         _       _     _           
    / \    _____   _ _ __ ___     / \  _   _| |_ ___  _ __ ___   __ _| |_(_) ___  _ __   \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
   / _ \  |_  / | | | '__/ _ \   / _ \| | | | __/ _ \| '_ ` _ \ / _` | __| |/ _ \| '_ \   \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
  / ___ \  / /| |_| | | |  __/  / ___ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | |   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
 /_/   \_\/___|\__,_|_|  \___| /_/   \_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_|    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/

  Module: az_automation_variables
  Description: This module creates Azure Automation Variables in an Azure Automation Account.
  Notes:
  - The plain text variable properties (name & description) are defined in resource blocks below.
  - The sensitive values are passed into Terraform as a TF_VAR that is set in GitLab's Pipeline Variables. 
  - Using Sensitive Strings (Secrets) in a For_Each loop is not supported in Terraform. Bypassing this will result in the secrets being stored in plain text in the Terraform state file.
  - Add a new resource block for each new variable that needs to be created.
*/

## Variables
resource "azurerm_automation_variable_string" "aa_tvar" {
  name                    = "TestVar"
  description             = "Test Variable"
  encrypted               = true
  value                   = var.aa_testVar_value
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
}
