# Hybrid workers

terraform {
  required_version = ">=1.4.0"
}

#Import Existing Automation Account (not TF managed)
data "azurerm_automation_account" "az_automation" {
  resource_group_name = var.resource_group_name
  name                = var.azure_automation_account_name
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
      subnet_id = var.hybrid_worker_subnet_id
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
    "Name"    = "domain.net"
    "OUPath"  = "OU=${local.pool_type},OU=${local.system_ou_name},OU=Azure,DC=domain,DC=net",
    "User"    = "${var.domain_join_upn}",
    "Restart" = "true",
    "Options" = "3"
  })
  protected_settings = jsonencode({
    "Password" = "${var.domain_join_pw}"
  })
}
/*
##NEEDS ACCESS TO AZURE AUTOMATION ACCOUNT TO GET DSC SERVER ENDPOINT AND TOKEN!!
## VMSS Extension - add hybrid worker custom script
locals {
  PSScriptName = "Add-HybridWorker.ps1"
  hwGroupName  = "HybridWorkerGroup${var.env}"
  hwEndPoint   = data.azurerm_automation_account.az_automation.dsc_server_endpoint
  hwToken      = data.azurerm_automation_account.az_automation.dsc_primary_access_key
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
  provision_after_extensions   = [azurerm_virtual_machine_scale_set_extension.vmss_ext_loganalytics.name]
  protected_settings = jsonencode({
    "commandToExecute" = "powershell.exe -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${local.base64EncodedScript}')) | Out-File -filepath ${local.PSScriptName}\" && powershell.exe -ExecutionPolicy Unrestricted -File ${local.PSScriptName} -GroupName ${local.hwGroupName} -EndPoint ${local.hwEndPoint} -Token ${local.hwToken}"
  })

  lifecycle {
    ignore_changes = [settings]
  }
}
*/

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