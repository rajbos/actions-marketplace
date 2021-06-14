# Actions Marketplace
Host a GitHub Actions Marketplace in your own organization.

This repo will check all repositories in the organization it sits in and write a actions-data.json to a new branch `organization-name/data`.

The goal is to host a GitHub Pages site in the same repository that pulls its data from the json file and displays the internal marketplace, with options to search.


# Schedule runs
The scheduled runs are planned at weekdays, at 7 AM.

# get-action-data.yml
The check-workflow will iterate all repositories in the same organization (or user) and find the ones that have actions in them. The information from the action.yml file will be parsed and stored in a new branch `organization-name/data`.

##### Note: This workflow can be triggered manually or will run on a schedule.

## Security 
To be able to push the incoming changes to the branch we need a GitHub Personal Access Token used in this workflow with the name `PAT_GITHUB`. This token needs to have the following scopes: `public_repo*, read:org, read:user, repo:status*, repo_deployment*, workflow`.

`*` These scopes are set by default when the `workflows` scope is set

# Contributions
<TODO> Please write an issue first, so we can discuss the direction before putting in to much work.

# Running locally
To run things locally you need to have PowerShell Core installed and to setup these parameters:

``` PowerShell
$fullRepositoryName="rajbos-actions/actions-marketplace"
$GITHUB_TOKEN="gh-xyz123"
$username = "Rob Bos" # will be used for commiting the changes
$useremail = "your-email@domain.com" # will be used for commiting the changes
```

Then you can call the updater to check all repositories in your organization:
``` PowerShell
.\src\updater.ps1 -orgName $fullRepositoryName -PAT $GITHUB_TOKEN -marketplaceRepo $fullRepositoryName -userName $username -userEmail $useremail
```