# Actions Marketplace
Goal: Host a GitHub Actions Marketplace in your own organization, more info [here](https://devopsjournal.io/blog/2021/10/14/GitHub-Actions-Internal-Marketplace).

This repo will check all repositories in the organization it sits in and write a actions-data.json to a new branch `gh-pages`.

# Steps to get things working
* Follow [best practices](https://devopsjournal.io/blog/2021/02/06/GitHub-Actions-Forking-Repositories) and fork any action you want to use in your organization to a specific organization hosting only actions.
* Keep the forks up to date using the [github-fork-updater](https://github.com/rajbos/github-fork-updater).
* Fork this repository over to the GitHub Actions Organization you created.
* Enable the `get-action-data` workflow in the forked repository.
* Host a GitHub Pages site in the forked repository that pulls its data from the json file and displays the internal marketplace, with options to search your internal actions. Got to `Settings` --> `Pages` and set it to the `gh-pages` branch.

# Schedule runs
The scheduled runs are planned at weekdays, at 7 AM.

# get-action-data.yml
The get-action-data will iterate all repositories in the same organization (or user) and find the ones that have actions in them by looking for an `action.yml` file in the root of the repository. The information from the action.yml file will be parsed and stored in a branch named `gh-pages`. On updating the file, [GitHub Pages](https://pages.github.com/) will be triggered to publish a new version of your website, with the latest data.
##### Note: This workflow can be triggered manually or will run on a schedule.

# GitHub Pages
Enable GitHub Pages on the `Settings` tab of your fork. Tell it to look for the pages in the `gh-pages` branch, since that is where the datafile will be located it needs to display the actions.


## Security 
When you fork this repository, you'll need to verify and then trust the automated workflow, before it will start to run. We use the default [GITHUB_TOKEN](https://docs.github.com/en/actions/reference/authentication-in-a-workflow) secret to write the data file back to the forked repository. We post the data file with our default user 'Marketplace Updater' that will show up in your git commit history. If you want to override these values, create these secrets and provide values:
* username
* useremail
# Contributions
<TODO> Please write an issue first, so we can discuss the direction before putting in to much work.

# Running locally: data file generation
To run things locally you need to have PowerShell Core installed and to setup these parameters:

``` PowerShell
$organization="rajbos-actions"
$marketplaceRepo="rajbos-actions/actions-marketplace"
$GITHUB_TOKEN="gh-xyz123"
$username = "Rob Bos" # will be used for commiting the changes
$useremail = "your-email@domain.com" # will be used for commiting the changes
```

Then you can call the updater to check all repositories in your organization:
``` PowerShell
.\src\updater.ps1 -orgName $organization -PAT $GITHUB_TOKEN -marketplaceRepo $marketplaceRepo -userName $username -userEmail $useremail
```

# Running locally: marketplace website testing:
Use a webhosting application to host the `index.html` file so you can test and debug it. Configure the `actions-data-url.txt` file to point to a filled json file with the correct structure (generate it once or use `https://raw.githubusercontent.com/rajbos-actions/actions-marketplace/gh-pages/actions-data.json`).
