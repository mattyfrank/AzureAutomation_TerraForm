output "resource_group_name" {
  value       = data.azurerm_resource_group.rg.name
  description = "Resource Group Name"
}

output "azure_automation_account_name" {
  value       = var.azure_automation_account_name
  description = "Automation Account Name"
}