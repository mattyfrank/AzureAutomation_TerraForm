### Azure Resources not Managed by TerraForm  

* AZ Resource Group
* AZ Automation Account

### Azure Resources Managed by Terraform  

* AZ Automation Runbook  
    * Source can by GitRepo or LocalFile  
* AZ Automation Schedule  
    * Daily  
    * Daily at 9PM  
    * Daily at 4AM  
* AZ Automation Jobs
    * Update-AutomationAzureModulesForAccount = Daily
    * Clear-VDI_Sessions = Daily @ 4:00 AM
    * Clear-VDI_Sessions = Daily @ 9:00 PM
* AZ Automation (PowerShell) Modules  
* AZ Automation Credentials  


## Example Steps to TF Deployment:

1. `az login`  

2. `az account set --subscription $SubscriptionID`  

3. `Set-Location .\TF-Example`  

4. `terraform init`  

5. `terraform plan -out=plan`  

6. `terraform apply plan`  

