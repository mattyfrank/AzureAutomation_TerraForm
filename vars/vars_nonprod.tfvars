/*
  _   _             ____                _  __     __         _       _     _           
 | \ | | ___  _ __ |  _ \ _ __ ___   __| | \ \   / /_ _ _ __(_) __ _| |__ | | ___  ___ 
 |  \| |/ _ \| '_ \| |_) | '__/ _ \ / _` |  \ \ / / _` | '__| |/ _` | '_ \| |/ _ \/ __|
 | |\  | (_) | | | |  __/| | | (_) | (_| |   \ V / (_| | |  | | (_| | |_) | |  __/\__ \
 |_| \_|\___/|_| |_|_|   |_|  \___/ \__,_|    \_/ \__,_|_|  |_|\__,_|_.__/|_|\___||___/
                                                                                       
*/

# Azure Resource Tags
tags = {
  description = "Azure Automation"
  managedBy   = "terraform"
  env         = "Nonprod"
  costCenter  = "123456"
  owner       = "Team_Name"
}

/*
# Azure Tenant, passed from GitLab CI/CD
azure_tenant_id = "abcde12345"

# Azure Subscription, passed from GitLab CI/CD
azure_subscription_id   = "00000000-0000-0000-0000-000000000000"
azure_subscription_name = "nonprod-management"
*/

# Azure Network
network_resource_group_name = "rg-nonprod-network"
virtual_network_name        = "network-001"
hybrid_subnet_name          = "snet-nonprod-001"

# Azure Resource Group
resource_group_name     = "rg-nonprod-automation-001"
resource_group_location = "eastus"

# Azure Automation Account
azure_automation_account_name = "aa-nonprd-001"

#Hybrid Worker Group
hybrid_worker_group_name = "hwg-nonprd-001"

# Azure Automation Schedules
automation_schedules = {
  aa_0000 = {
    name        = "Hourly_0000"
    start_time  = "T00:00:00"
    description = "Hourly starting at 12:00 AM"
    frequency   = "Hour"
    week_days   = null
    month_days  = null
  },
  aa_2000 = {
    name        = "Daily_2000"
    start_time  = "T20:00:00"
    description = "Daily at 08:00 PM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  }
  aa_2100 = {
    name        = "Daily_2100"
    start_time  = "T21:00:00"
    description = "Daily at 9:00 PM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_2200 = {
    name        = "Daily_2200"
    start_time  = "T22:00:00"
    description = "Daily at 10:00 PM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_2300 = {
    name        = "Daily_2300"
    start_time  = "T23:00:00"
    description = "Daily at 11:00 PM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0000 = {
    name        = "Daily_0000"
    start_time  = "T00:00:00"
    description = "Daily at 12:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0100 = {
    name        = "Daily_0100"
    start_time  = "T01:00:00"
    description = "Daily at 01:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0200 = {
    name        = "Daily_0200"
    start_time  = "T02:00:00"
    description = "Daily at 02:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0230 = {
    name        = "Daily_0230"
    start_time  = "T02:30:00"
    description = "Daily at 02:30 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0300 = {
    name        = "Daily_0300"
    start_time  = "T03:00:00"
    description = "Daily at 03:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0330 = {
    name        = "Daily_0330"
    start_time  = "T03:30:00"
    description = "Daily at 03:30 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0400 = {
    name        = "Daily_0400"
    start_time  = "T04:00:00"
    description = "Daily at 04:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0430 = {
    name        = "Daily_0430"
    start_time  = "T04:30:00"
    description = "Daily at 04:30 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0500 = {
    name        = "Daily_0500"
    start_time  = "T05:00:00"
    description = "Daily at 05:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0600 = {
    name        = "Daily_0600"
    start_time  = "T06:00:00"
    description = "Daily at 06:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  },
  aa_0700 = {
    name        = "Daily_0700"
    start_time  = "T07:00:00"
    description = "Daily at 07:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  }
  aa_0800 = {
    name        = "Daily_0800"
    start_time  = "T08:00:00"
    description = "Daily at 08:00 AM"
    frequency   = "Day"
    week_days   = null
    month_days  = null
  }
  aa_wednesday = {
    name        = "Weekly_Wednesday_0830"
    start_time  = "T08:30:00"
    description = "Wednesday at 8:30 AM"
    frequency   = "Week"
    week_days   = ["Wednesday"]
    month_days  = null
  },
  aa_friday = {
    name        = "Weekly_Friday_2300"
    start_time  = "T23:00:00"
    description = "Friday at 11:00 PM"
    frequency   = "Week"
    week_days   = ["Friday"]
    month_days  = null
  },
  aa_saturday = {
    name        = "Weekly_Saturday_0300"
    start_time  = "T03:00:00"
    description = "Saturday at 03:00 AM"
    frequency   = "Week"
    week_days   = ["Saturday"]
    month_days  = null
  }
  aa_first = {
    name        = "First_and_Fifteenth"
    start_time  = "T00:00:00"
    description = "Monthly on First and Fifteenth"
    frequency   = "Month"
    week_days   = null
    month_days  = [1, 15]
  }
  # Add more hourly schedules here...
}

#Job Schedule (assign schedule to runbook)
automation_job_schedules = {
  /*
  000 = {
    schedule_name = "aa_0000"
    runbook_name  = "EXAMPLE.ps1"
    hybrid_worker = true/false
  },
  */
  001 = {
    schedule_name = "aa_2100"
    runbook_name  = "Horizon-Disconnect-Old_Sessions.ps1"
    hybrid_worker = true
  },
  002 = {
    schedule_name = "aa_2200"
    runbook_name  = "Horizon-Reset-Old_VMs.ps1"
    hybrid_worker = true
  },
  003 = {
    schedule_name = "aa_2300"
    runbook_name  = "Horizon-Clear-Deleting_VMs.ps1"
    hybrid_worker = true
  },
  004 = {
    schedule_name = "aa_0030"
    runbook_name  = "Horizon-Disconnect-Old_Sessions.ps1"
    hybrid_worker = true
  },
  005 = {
    schedule_name = "aa_0100"
    runbook_name  = "Horizon-Reset-Old_VMs.ps1"
    hybrid_worker = true
  },
  006 = {
    schedule_name = "aa_0300"
    runbook_name  = "Horizon-Clear-Deleting_VMs.ps1"
    hybrid_worker = false
  } #,
  //010 = {Config Manager Jobs},
  //020 = {InTune Jobs},
  //030 = {Active Directory Jobs},
  //040 = {Auto-Package Jobs},
  //050 = {Inventory Jobs},
  //060 = {Billing Jobs},
  //070 = {Entra ID Jobs},
  //Add more job schedules here...
}

## Azure Automation Modules
//Does Not Support RunTime Env (Preview)
automation_powershell_5_modules = {
  # az_account   = "Az.Accounts"
  # az_compute   = "Az.Compute"
  # az_network   = "Az.Network"
  # az_storage   = "Az.Storage"
  # az_managedid = "Az.ManagedServiceIdentity"
  # Add more modules here...
}
automation_powershell_7_modules = {
  # uri       = "https://devopsgallerystorage.blob.core.windows.net/packages/xactivedirectory.2.19.0.nupkg"
  # az_intune = "https://devopsgallerystorage.blob.core.windows.net/packages/microsoft.graph.intune.6.1907.1.nupkg"
  # az_entra  = "https://devopsgallerystorage.blob.core.windows.net/packages/microsoft.graph.entra.0.11.0-preview.nupkg"
  # Add more modules here...
}

# Azure Automation Credentials, passed from GitLab CI/CD
aa_hasa_pw = "Example-Secret123!"

# Azure Automation Variables, passed from GitLab CI/CD
aa_testVar_value = "Example-Var123!"

#Hybrid Worker Domain Join Credentials, passed from GitLab CI/CD
domain_join_upn  = "DomainJoinUser"
domain_join_pw   = "SecretPassword"
local_admin_user = "LocalAdminUser"
local_admin_pw   = "SecretPassword"