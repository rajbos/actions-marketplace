# Actions Marketplace
Goal: Host a GitHub Actions Marketplace in your own organization, more info [here](https://devopsjournal.io/blog/2021/10/14/GitHub-Actions-Internal-Marketplace).

This repo will check all repositories in the organization it sits in and write a actions-data.json to a new branch `gh-pages`.

# Steps to get things working
* Follow [best practices](https://devopsjournal.io/blog/2021/02/06/GitHub-Actions-Forking-Repositories) and fork any action you want to use in your organization to a specific organization hosting only actions.
* Keep the forks up to date using the [github-fork-updater](https://github.com/rajbos/github-fork-updater).
* Fork this repository over to the GitHub Actions Organization you created.
* Enable the `get-action-data` workflow in the forked repository.
* Configure GitHub Pages in your forked repository:
  1. Go to `Settings` → `Pages`
  2. Under "Build and deployment", set **Source** to: **GitHub Actions** (not "Deploy from a branch")
  3. The workflows will automatically deploy your marketplace site
* The marketplace will pull action data from the JSON file generated in the `gh-pages` branch and display your internal actions with search functionality.

# Schedule runs
The scheduled runs are planned at weekdays, at 7 AM.

# get-action-data.yml
The get-action-data will iterate all repositories in the same organization (or user) and find the ones that have actions in them by looking for an `action.yml` file in the root of the repository. The information from the action.yml file will be parsed and stored in a branch named `gh-pages`. On updating the file, [GitHub Pages](https://pages.github.com/) will be triggered to publish a new version of your website, with the latest data.
##### Note: This workflow can be triggered manually or will run on a schedule.

# All Workflows Overview

This repository uses several GitHub Actions workflows for different purposes:

## Core Workflows

### 1. `get-action-data.yml` - Action Data Collection
- **Purpose:** Scans organization repositories to find and catalog available GitHub Actions
- **Schedule:** Runs weekdays at 7 AM UTC (cron: `7 0 * * 1-5`)
- **Also triggers on:** Push to `main`, manual workflow dispatch
- **Output:** Creates `actions-data.json` in `gh-pages` branch with metadata about all discovered actions
- **Permissions:** Requires `contents: write` to commit to `gh-pages` branch

### 2. `sync-to-gh-pages.yml` - Static File Management
- **Purpose:** Syncs website files (HTML, CSS, JS) from `main` to `gh-pages` branch
- **Triggers on:** Changes to `index.html`, `script.js`, `style.css`, or `_includes/` in `main` branch
- **Features:**
  - Implements cache-busting with timestamp-based version parameters
  - Adds deployment metadata to HTML
  - Ensures `.nojekyll` file is present
- **Permissions:** Requires `contents: write` to push to `gh-pages` branch

### 3. `jekyll-gh-pages.yml` - GitHub Pages Deployment
- **Purpose:** Deploys the site to GitHub Pages using the Actions deployment method
- **Triggers on:** Any push to `gh-pages` branch, manual dispatch
- **Process:** Builds with Jekyll and deploys to Pages environment
- **Permissions:** Requires `pages: write` and `id-token: write` for deployment

## Supporting Workflows

### 4. `visual-test.yml` - UI Testing
- **Purpose:** Captures visual screenshots of the marketplace UI for pull request review
- **Triggers on:** Pull requests that modify `index.html`, `style.css`, or `script.js`
- **Output:** Screenshots (desktop, mobile, tablet views) uploaded as workflow artifacts
- **Note:** Helps reviewers see UI changes before merging

### 5. `get-action-usages.yml` - Usage Analytics
- **Purpose:** Analyzes which actions are being used across the organization
- **Triggers on:** Push to `used-actions` branch, manual dispatch
- **Output:** `summarized-actions.json` artifact with usage statistics
- **Requirements:** Runs in a custom PowerShell container

### 6. `build-image.yml` - Container Build
- **Purpose:** Builds and publishes the PowerShell container image used by other workflows
- **Triggers on:** Push to `main`, `used-actions`, or `fix-module` branches
- **Output:** Container image at `ghcr.io/rajbos/actions-marketplace/powershell:7`

### 7. `new-issue.yml` - Project Management
- **Purpose:** Automatically adds new issues to a GitHub project board
- **Triggers on:** New issue creation
- **Requirements:** Needs `PROJECT_TOKEN`, `PROJECT_ACCOUNT`, and `PROJECT_NUMBER` secrets

# GitHub Pages

## How GitHub Pages Publishing Works

This repository uses **GitHub Actions to publish to GitHub Pages**, not branch-based publishing. The deployment involves two key workflows working together:

### Deployment Method: GitHub Actions

**Configuration Required:**
1. Go to `Settings` → `Pages` in your forked repository
2. Under "Build and deployment", set **Source** to: **GitHub Actions** (not "Deploy from a branch")
3. This allows the workflows to deploy directly to GitHub Pages using the Actions deployment mechanism

### Two-Workflow Deployment Process

#### 1. Content Management: `sync-to-gh-pages.yml`
This workflow manages the static website files (HTML, CSS, JavaScript) by syncing them from `main` to `gh-pages` branch:

**Purpose:** Keep the `gh-pages` branch updated with the latest website files
- **Triggers:** 
  - Automatically when `index.html`, `script.js`, `style.css`, or `_includes/` files change in `main` branch
  - Manually via workflow dispatch
- **What it does:**
  - Copies static files from `main` to `gh-pages` branch
  - Implements cache-busting by updating version parameters (`?v=timestamp`) on CSS/JS references
  - Adds deployment metadata (branch, commit, timestamp) to the HTML
  - Ensures the `.nojekyll` file is present to disable Jekyll processing
- **Branch Role:** The `gh-pages` branch serves as a staging area for all website content before deployment

#### 2. Deployment: `jekyll-gh-pages.yml`
This workflow actually publishes the site to GitHub Pages:

**Purpose:** Deploy the `gh-pages` branch content to the live GitHub Pages site
- **Triggers:** 
  - Automatically when changes are pushed to the `gh-pages` branch
  - Manually via workflow dispatch
- **What it does:**
  - Checks out the `gh-pages` branch
  - Builds the site using Jekyll (though `.nojekyll` prevents Jekyll transformation)
  - Uploads the built site as a Pages artifact
  - Deploys to the live GitHub Pages environment
- **Permissions:** Requires `pages: write` and `id-token: write` permissions for deployment

### The Complete Flow

```
Main Branch Changes
    ↓
[sync-to-gh-pages.yml runs]
    ↓
Files copied to gh-pages branch
    ↓
[jekyll-gh-pages.yml triggered]
    ↓
Site deployed to GitHub Pages
    ↓
Live at https://[owner].github.io/actions-marketplace/
```

### Data File Updates (`get-action-data.yml`)

The action data (JSON file) is updated separately:
- **Triggers:** Push to `main`, schedule (weekdays at 7 AM), or manual dispatch
- **Process:** 
  - Scans all repositories in the organization for `action.yml` files
  - Generates `actions-data.json` with action metadata
  - Uploads the JSON directly to the `gh-pages` branch
  - This triggers `jekyll-gh-pages.yml` to redeploy with updated data

### Key Files

- **`.nojekyll`**: Empty file that disables Jekyll processing, preventing theme interference with custom CSS and eliminating build delays. Must exist in `main` branch to be synced to `gh-pages`.
- **`_config.yml`**: Contains minimal Jekyll configuration with theme removed to prevent CSS conflicts.
- **`actions-data-url.txt`**: Points to the JSON data file location.

### Cache Busting

The `sync-to-gh-pages.yml` workflow implements automatic cache busting:
- Updates version parameters (`?v=timestamp`) on CSS and JS references in `index.html`
- Forces browsers to reload updated files instead of using cached versions
- The `index.html` in `main` branch has placeholder versions that get replaced during sync

### Important Notes

- ⚠️ **Do not** configure Pages to deploy from the `gh-pages` branch directly - this would bypass the Jekyll workflow
- ✅ **Do** set Pages source to "GitHub Actions" in repository settings
- The `gh-pages` branch is an intermediate storage location, not the direct publishing source
- Both workflows must remain enabled for the deployment to function correctly


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
