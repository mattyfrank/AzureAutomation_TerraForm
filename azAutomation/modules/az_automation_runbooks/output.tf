output "azure_automation_runbooks" {
  value = values(azurerm_automation_runbook.runbooks)[*].name
}
output "azure_automation_update_modules" {
  value = azurerm_automation_runbook.runbook_update_modules
}
