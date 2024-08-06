/*
     _                             _         _                        _   _               ____       _              _       _           
    / \    _____   _ _ __ ___     / \  _   _| |_ ___  _ __ ___   __ _| |_(_) ___  _ __   / ___|  ___| |__   ___  __| |_   _| | ___  ___ 
   / _ \  |_  / | | | '__/ _ \   / _ \| | | | __/ _ \| '_ ` _ \ / _` | __| |/ _ \| '_ \  \___ \ / __| '_ \ / _ \/ _` | | | | |/ _ \/ __|
  / ___ \  / /| |_| | | |  __/  / ___ \ |_| | || (_) | | | | | | (_| | |_| | (_) | | | |  ___) | (__| | | |  __/ (_| | |_| | |  __/\__ \
 /_/   \_\/___|\__,_|_|  \___| /_/   \_\__,_|\__\___/|_| |_| |_|\__,_|\__|_|\___/|_| |_| |____/ \___|_| |_|\___|\__,_|\__,_|_|\___||___/
                                                                                                                                                                                                                
  Notes:
    - Schedules are defined as Hourly, Daily, Weekly, and Monthly.
    - local variables for time, 
    - get tomorrow data/time so schedules are in the future
    - get timezone for local time
    - timezone is set to PDT or PST
*/

locals {
  tomorrow = formatdate("YYYY-MM-DD", timeadd(timestamp(), "24h"))
  timezone = "-04:00" //(EDT)
  # timezone = "-05:00"   //(EST)
}

## Automation Schedules
resource "azurerm_automation_schedule" "aa_schedules" {
  for_each                = var.automation_schedules
  resource_group_name     = var.resource_group_name
  automation_account_name = var.azure_automation_account_name
  name                    = each.value.name
  description             = each.value.description
  frequency               = each.value.frequency
  start_time              = join("", ["${local.tomorrow}", "${each.value.start_time}", "${local.timezone}"])
  week_days               = each.value.week_days
  month_days              = each.value.month_days
  interval                = 1
  timezone                = "America/New_York"
}
