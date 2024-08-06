/* 
     _                             _         _                        _   _              
    / \    _____   _ _ __ ___     / \  _   _| |_ ___  _ __ ___   __ _| |_(_) ___  _ __   
   / _ \  |_  / | | | '__/ _ \   / _ \| | | | __/ _ \| '_ ` _ \ / _` | __| |/ _ \| '_ \  
  / ___ \  / /| |_| | | |  __/  / ___ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | | 
 /_/__ \_\/___|\__,_|_|  \___| /_/  _\_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_| 
 / ___|  ___  _   _ _ __ ___ ___   / ___|___  _ __ | |_ _ __ ___ | |                     
 \___ \ / _ \| | | | '__/ __/ _ \ | |   / _ \| '_ \| __| '__/ _ \| |                     
  ___) | (_) | |_| | | | (_|  __/ | |__| (_) | | | | |_| | | (_) | |                     
 |____/ \___/ \__,_|_|  \___\___|  \____\___/|_| |_|\__|_|  \___/|_|                     
                                                                                         
Description: Manage Azure Automation with Terraform. Designed to be run from GitLab CICD with variables being injected at run time. Terraform backend is hosted on the GitLab project.

Pipeline environmental variables:
  - Azure_Managed_ID
  - Azure_Managed_PW
  - Azure_Subscription_ID
  - Azure_Tenant_ID

Notes: 
  - Requires Managed Identity to be created and assigned to the Azure Automation account.
  - The Managed ID Account is created in the Azure Portal.
  - The Managed ID Account is used to authenticate against Azure Resources.
  - The Managed ID Account is assigned to the Azure Automation Account.
  - The Managed ID Acccount has been delegated necessary access/roles.
*/


## Azure Resource Group - Import Existing ResourceGroup (not TF managed)
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

/*
     _                             _   
    / \   ___ ___ ___  _   _ _ __ | |_ 
   / _ \ / __/ __/ _ \| | | | '_ \| __|
  / ___ \ (_| (_| (_) | |_| | | | | |_ 
 /_/   \_\___\___\___/ \__,_|_| |_|\__|
*/

## Azure Automation Account - Import Existing AutomationAccount (not TF managed)
data "azurerm_automation_account" "az_automation" {
  resource_group_name = var.resource_group_name
  name                = var.azure_automation_account_name
}

/*
 __        __         _                ____                       
 \ \      / /__  _ __| | _____ _ __   / ___|_ __ ___  _   _ _ __  
  \ \ /\ / / _ \| '__| |/ / _ \ '__| | |  _| '__/ _ \| | | | '_ \ 
   \ V  V / (_) | |  |   <  __/ |    | |_| | | | (_) | |_| | |_) |
    \_/\_/ \___/|_|  |_|\_\___|_|     \____|_|  \___/ \__,_| .__/ 
                                                           |_|    
Automation Account Hybrid Worker Group
*/

// Not In Use - Hybrid Worker VMs will be in seperate pipeline
## Azure Network Resource Group - Import Network Resource Group (not TF Managed)
data "azurerm_resource_group" "rg_network" {
  name = var.network_resource_group_name
}
## Azure SubNet - Import Existing Virtual Network (not TF Managed)
data "azurerm_subnet" "subnet_mgmt" {
  name                 = var.hybrid_subnet_name
  resource_group_name  = var.network_resource_group_name
  virtual_network_name = var.virtual_network_name
}


## Create Automation Account Hybrid Worker Group
resource "azurerm_automation_hybrid_runbook_worker_group" "aa_hybrid_worker_group" {
  name                    = var.hybrid_worker_group_name
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
}

/*
  ____              _                 _        
 |  _ \ _   _ _ __ | |__   ___   ___ | | _____ 
 | |_) | | | | '_ \| '_ \ / _ \ / _ \| |/ / __|
 |  _ <| |_| | | | | |_) | (_) | (_) |   <\__ \
 |_| \_\\__,_|_| |_|_.__/ \___/ \___/|_|\_\___/
                                               
Create Runbooks in Azure Automation Account
*/

## Module: Azure Automation Runbooks
module "az_automation_runbooks" {
  source                        = "./modules/az_automation_runbooks"
  env                           = var.env
  tags                          = var.tags
  resource_group_location       = data.azurerm_resource_group.rg.location #var.resource_group_location
  resource_group_name           = data.azurerm_resource_group.rg.name     #var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name
}

/*
  ____       _              _       _           
 / ___|  ___| |__   ___  __| |_   _| | ___  ___ 
 \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \/ __|
  ___) | (__| | | |  __/ (_| | |_| | |  __/\__ \
 |____/ \___|_| |_|\___|\__,_|\__,_|_|\___||___/
                                                
*/

## Module: Azure Automation Schedules
module "az_automation_schedules" {
  source                        = "./modules/az_automation_schedules"
  env                           = var.env
  tags                          = var.tags
  resource_group_name           = data.azurerm_resource_group.rg.name #var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name
  automation_schedules          = var.automation_schedules
}

/*
      _       _       ____       _              _       _           
     | | ___ | |__   / ___|  ___| |__   ___  __| |_   _| | ___  ___ 
  _  | |/ _ \| '_ \  \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \/ __|
 | |_| | (_) | |_) |  ___) | (__| | | |  __/ (_| | |_| | |  __/\__ \
  \___/ \___/|_.__/  |____/ \___|_| |_|\___|\__,_|\__,_|_|\___||___/

Azure Automation Job Schedules
*/

## Module: Azure Automation Job Schedules
module "az_automation_jobs" {
  count                             = try(var.env == "prod" ? 1 : 0) #Create Resource if in Production  
  source                            = "./modules/az_automation_jobs"
  env                               = var.env
  resource_group_name               = data.azurerm_resource_group.rg.name #var.resource_group_name
  automation_runbooks               = module.az_automation_runbooks.azure_automation_runbooks
  automation_runbook_update_modules = module.az_automation_runbooks.azure_automation_update_modules
  automation_schedules              = module.az_automation_schedules.azure_automation_schedules
  azure_automation_account_name     = var.azure_automation_account_name
  automation_job_schedules          = var.automation_job_schedules
  hybrid_worker_group_name          = var.hybrid_worker_group_name
}

/*
   ____              _            _   _       _     
  / ___|_ __ ___  __| | ___ _ __ | |_(_) __ _| |___ 
 | |   | '__/ _ \/ _` |/ _ \ '_ \| __| |/ _` | / __|
 | |___| | |  __/ (_| |  __/ | | | |_| | (_| | \__ \
  \____|_|  \___|\__,_|\___|_| |_|\__|_|\__,_|_|___/
                                                    
*/

## Module: Azure Automation Credentials
module "az_automation_creds" {
  count                         = try(var.env == "prod" ? 1 : 0) #Create Resource if in Production  
  source                        = "./modules/az_automation_creds"
  env                           = var.env
  resource_group_name           = var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name
  aa_hasa_pw                    = var.aa_hasa_pw #TF_VAR_aa_hasa_pw
}
/*
 __     __         _       _     _           
 \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
                                             
*/

## Module: Azure Runbook variables
module "az_automation_variables" {
  count                         = try(var.env == "prod" ? 1 : 0) #Create Resource if in Production  
  source                        = "./modules/az_automation_variables"
  env                           = var.env
  resource_group_name           = var.resource_group_name
  azure_automation_account_name = var.azure_automation_account_name
  aa_testVar_value              = var.aa_testVar_value #TF_VAR_aa_testVar_value
}

/*
  __  __           _       _           
 |  \/  | ___   __| |_   _| | ___  ___ 
 | |\/| |/ _ \ / _` | | | | |/ _ \/ __|
 | |  | | (_) | (_| | |_| | |  __/\__ \
 |_|  |_|\___/ \__,_|\__,_|_|\___||___/

Azure Automation Modules for Runbooks
*/

//Not In Use
#Module: Azure Automation Modules
module "az_automation_modules" {
  source                          = "./modules/az_automation_modules"
  env                             = var.env
  resource_group_name             = var.resource_group_name
  azure_automation_account_name   = var.azure_automation_account_name
  azure_automation_account_id     = data.azurerm_automation_account.az_automation.id
  automation_powershell_5_modules = var.automation_powershell_5_modules
  automation_powershell_7_modules = var.automation_powershell_7_modules
}


/*
 __     ____  __   ____            _        ____       _   
 \ \   / /  \/  | / ___|  ___ __ _| | ___  / ___|  ___| |_ 
  \ \ / /| |\/| | \___ \ / __/ _` | |/ _ \ \___ \ / _ \ __|
   \ V / | |  | |  ___) | (_| (_| | |  __/  ___) |  __/ |_ 
    \_/  |_|  |_| |____/ \___\__,_|_|\___| |____/ \___|\__|
Azure VM Scale Set for Hybrid Workers                                                           
*/

//Storage Blob for hosting init files?
## Module: Azure VM Scale Set and Hybrid Worker
module "az_hybridworker" {
  source                        = "./modules/hybrid_workers"
  env                           = var.env
  resource_group_location       = data.azurerm_resource_group.rg.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  azure_automation_account_name = var.azure_automation_account_name
  network_resource_group_name   = var.network_resource_group_name
  virtual_network_name          = var.virtual_network_name
  hybrid_subnet_name            = var.hybrid_subnet_name
  domain_join_pw                = var.domain_join_pw   #from CICD variables
  domain_join_upn               = var.domain_join_upn  #from CICD variables
  local_admin_pw                = var.local_admin_pw   #from CICD variables
  local_admin_user              = var.local_admin_user #from CICD variables
  tags                          = var.tags
  hybrid_worker_group_name      = var.hybrid_worker_group_name
}

