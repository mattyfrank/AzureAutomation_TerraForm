# Create Local Repo from GitLab Project
git clone -n --depth=1 --filter=tree:0 https://GIT_SERVER.DOMAIN.NET/azure-automation/az-automation-pr0d-01.git git_repo

# Change Directory to AZ Automation
cd git_repo

# Only Check-Out Runbooks Folder
git sparse-checkout set --no-cone Runbooks

# Check-Out
git checkout

#Clean-Up Files in Post Deployment? 