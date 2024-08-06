output "azure_automation_jobs" {
  value = values(var.automation_job_schedules)[*].schedule_name
  #value = values(azurerm_automation_job_schedule.aa_job_schedules[*]).schedule_name    #Can't access attributes on a list of objects.
}
