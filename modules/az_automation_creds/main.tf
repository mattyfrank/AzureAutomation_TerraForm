/*
    _                        _       _                  _   _             ___            _         _   _      _    
   /_\   ____  _ _ _ ___    /_\ _  _| |_ ___ _ __  __ _| |_(_)___ _ _    / __|_ _ ___ __| |___ _ _| |_(_)__ _| |___
  / _ \ |_ / || | '_/ -_)  / _ \ || |  _/ _ \ '  \/ _` |  _| / _ \ ' \  | (__| '_/ -_) _` / -_) ' \  _| / _` | (_-<
 /_/ \_\/__|\_,_|_| \___| /_/ \_\_,_|\__\___/_|_|_\__,_|\__|_\___/_||_|  \___|_| \___\__,_\___|_||_\__|_\__,_|_/__/
                                                                                                                   

  Module: az_automation_creds
  Description: This module is used to create Azure Automation Credentials for various service accounts used in the Azure Automation account.
  Notes:
    - The plain text credential properties (name, username, description) are defined in resource blocks below.
    - The sectets (passwords) are passed into Terraform as a TF_VAR that is set in GitLab's Pipeline Variables. 
    - Using Sensitive Strings (Secrets) in a For_Each loop is not supported in Terraform. Bypassing this will result in the secrets being stored in plain text in the Terraform state file.
    - Add a new resource block for each new service account that needs to be created.
*/

locals {
  domain     = "DOMAIN"
  domain_ext = "net"
}

//Hardcoded Credentials
resource "azurerm_automation_credential" "aa_hasa" {
  name                    = "Horizon Admin Service Account"
  username                = "UserName@${local.domain}.${local.domain_ext}"
  description             = "Service Account for Horizon API calls"
  password                = var.aa_hasa_pw
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
}
