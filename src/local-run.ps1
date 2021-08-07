
# execute the updated script that writes to the data file in the marketplace repo
#.\updater.ps1 -orgName $orgName -PAT $env:GITHUB_TOKEN -marketplaceRepo $marketplaceRepo -userName $username -userEmail $userEmail

# excecute the script that loads all used actions from all repos in the org
$orgName = 'rajbos'
$marketplaceRepo = ''
$username = 'rajbos'
$userEmail = ''
.$PSScriptRoot\load-used-actions.ps1 -orgName $orgName -PAT $env:GITHUB_TOKEN -marketplaceRepo $marketplaceRepo -userName $username -userEmail $userEmail

