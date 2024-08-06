# Source Control between Azure Automation and git Repository  

### Azure Resources not Managed by TerraForm  
#### Import Azure Resources as a data source  
* AZ Resource Group  
* AZ Automation Account  

### Azure Resources Managed by Terraform  
#### Create Azure Resources  
* AZ Automation Runbooks  
    * Source can be URL or LocalFile  
* AZ Automation Schedules  
* AZ Automation Jobs
* AZ Automation Credentials  
* AZ Automation Variables  
* AZ Automation Modules (Not supported in RunTime Env Preview)  
* AZ VM Scale Set  
    * Create VMs, Join Domain, Join Hybrid WOrker Group


### Example Steps to TF Deployment:

1. `az login`  

2. `az account set --subscription "$SubscriptionID"`  

3. `cd .\AZ_Automation`  

4. `terraform fmt -recursive`  

5. `terraform init`  or `terraform init -upgrade`  

6. `terraform plan -var-file="vars/vars_$ENV.tfvars" -out=plan`  

7. `terraform apply plan`  

