/*
  ____                 _     _               
 |  _ \ _ __ _____   _(_) __| | ___ _ __ ___ 
 | |_) | '__/ _ \ \ / / |/ _` |/ _ \ '__/ __|
 |  __/| | | (_) \ V /| | (_| |  __/ |  \__ \
 |_|   |_|  \___/ \_/ |_|\__,_|\___|_|  |___/

*/
terraform {
  required_version = ">=1.9.0" #github.com/hashicorp/terraform/releases

  //GitLab hosted backend for state files
  backend "http" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.114.0" #registry.terraform.io/providers/hashicorp/azurerm
    }
  }
}

# Azure Resource Manager Provider
provider "azurerm" {
  features {}
}
