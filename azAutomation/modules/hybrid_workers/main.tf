/*
 __   ____  __   ___          _       ___      _                  _   _  _      _        _    _  __      __       _              
 \ \ / /  \/  | / __| __ __ _| |___  / __| ___| |_   __ _ _ _  __| | | || |_  _| |__ _ _(_)__| | \ \    / /__ _ _| |_____ _ _ ___
  \ V /| |\/| | \__ \/ _/ _` | / -_) \__ \/ -_)  _| / _` | ' \/ _` | | __ | || | '_ \ '_| / _` |  \ \/\/ / _ \ '_| / / -_) '_(_-<
   \_/ |_|  |_| |___/\__\__,_|_\___| |___/\___|\__| \__,_|_||_\__,_| |_||_|\_, |_.__/_| |_\__,_|   \_/\_/\___/_| |_\_\___|_| /__/
                                                                           |__/                                                  

Module: Hybrid Worker
Description: This module creates a Windows Virtual Machine Scale Set (VMSS) with a Hybrid Worker extension to join the VMSS to an Azure Automation Account. The VMSS is configured with an autoscale policy based on CPU usage.
Architecture: 
  1. Create a Windows Virtual Machine Scale Set (VMSS)
  2. Join the VMSS to an Azure Automation Account
  3. Add a Hybrid Worker extension to the VMSS
  4. Configure an autoscale policy based on CPU usage
*/

#Import Existing Automation Account (not TF managed)
data "azurerm_automation_account" "az_automation" {
  resource_group_name = var.resource_group_name
  name                = var.azure_automation_account_name
}

#Import Existing Subnet (not TF managed)
data "azurerm_subnet" "hybrid_worker_subnet" {
  name                 = var.hybrid_subnet_name
  resource_group_name  = var.network_resource_group_name
  virtual_network_name = var.virtual_network_name
}

## Build system info
locals {
  system_name_type = (var.env == "prod" ? "prd" : "np")
  system_ou_name   = (var.env == "prod" ? "Prod" : "NonProd")
}

locals {
  pool_type = "hw"
  vm_prefix = upper("vmapp-${local.system_name_type}")
}

locals {
  domain     = "DOMAIN"
  domain_ext = "net"

}

## Virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "vmss_hw" {
  name                                              = "vmss-${var.env}-hybridworker"
  computer_name_prefix                              = local.vm_prefix
  location                                          = var.resource_group_location
  resource_group_name                               = var.resource_group_name
  sku                                               = "Standard_B2s"
  instances                                         = 1
  enable_automatic_updates                          = true
  timezone                                          = "Pacific Standard Time"
  admin_username                                    = "LocalUserName"  #var.local_admin_username
  admin_password                                    = "LocalPassword!" #var.local_admin_pw
  do_not_run_extensions_on_overprovisioned_machines = true
  tags                                              = var.tags
  upgrade_mode                                      = "Manual" #"Automatic"

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-22h2-ent"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = "127"
  }

  network_interface {
    name    = "hybridworker-vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = data.azurerm_subnet.hybrid_worker_subnet.id
    }
  }

  lifecycle {
    ignore_changes = [instances]
  }
}

## VMSS Extension - join domain
resource "azurerm_virtual_machine_scale_set_extension" "vmss_ext_domainJoin" {
  name                         = "vmss-domainjoin"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss_hw.id
  publisher                    = "Microsoft.Compute"
  type                         = "JsonADDomainExtension"
  type_handler_version         = "1.3"
  auto_upgrade_minor_version   = true
  settings = jsonencode({
    "Name"    = "${local.domain}.${local.domain_ext}",
    "OUPath"  = "OU=${local.pool_type},OU=${local.system_ou_name},OU=AZ,DC=${local.domain},DC=${local.domain_ext}",
    "User"    = "${var.domain_join_upn}",
    "Restart" = "true",
    "Options" = "3"
  })
  protected_settings = jsonencode({
    "Password" = "${var.domain_join_pw}"
  })
}

##NEEDS ACCESS TO AZURE AUTOMATION ACCOUNT TO GET DSC SERVER ENDPOINT AND TOKEN!!
## VMSS Extension - add hybrid worker custom script
locals {
  PSScriptName = "Add-HybridWorker.ps1"
  hwGroupName  = "HybridWorkerGroup${var.env}"
  hwEndPoint   = data.azurerm_automation_account.az_automation.endpoint
  hwToken      = data.azurerm_automation_account.az_automation.primary_key
}

locals {
  PSScript            = try(file("${path.module}/scripts/${local.PSScriptName}"), null)
  base64EncodedScript = base64encode(local.PSScript)
}

resource "azurerm_virtual_machine_scale_set_extension" "vmss_ext_script_hw" {
  name                         = "vmss-customscript-hw"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss_hw.id
  publisher                    = "Microsoft.Compute"
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"
  auto_upgrade_minor_version   = true
  provision_after_extensions   = [azurerm_virtual_machine_scale_set_extension.vmss_ext_domainJoin.name]
  protected_settings = jsonencode({
    "commandToExecute" = "powershell.exe -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${local.base64EncodedScript}')) | Out-File -filepath ${local.PSScriptName}\" && powershell.exe -ExecutionPolicy Unrestricted -File ${local.PSScriptName} -GroupName ${local.hwGroupName} -EndPoint ${local.hwEndPoint} -Token ${local.hwToken}"
  })

  lifecycle {
    ignore_changes = [settings]
  }
}

## Autoscale policy
resource "azurerm_monitor_autoscale_setting" "autoscale_vmss" {
  name                = "vmss-autoscale"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss_hw.id
  tags                = var.tags

  profile {
    name = "Autoscale 15 < CPU > 75"

    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss_hw.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss_hw.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }
}