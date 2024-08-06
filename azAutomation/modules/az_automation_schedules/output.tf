output "azure_automation_schedules" {
  value = values(azurerm_automation_schedule.aa_schedules)[*].name
}
