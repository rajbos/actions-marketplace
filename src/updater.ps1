# example calls:
# .\updater.ps1 -orgName "rajbos-actions" -userName "xxx" -PAT $env:GitHubPAT -$marketplaceRepo "rajbos/actions-marketplace"
param (
    [string] $orgName,
    [string] $userName,
    [string] $PAT,
    [string] $marketplaceRepo,
    [string] $userEmail
)

# pull in central calls library
. $PSScriptRoot\github-calls.ps1

# placeholder to enable testing locally later on
$testingLocally = $false

function FindAllRepos {
    param (
        [string] $orgName,
        [string] $userName,
        [string] $PAT
    )

    $url = "https://api.github.com/orgs/$orgName/repos"
    $info = CallWebRequest -url $url -userName $userName -PAT $PAT

    if ($info -eq "https://docs.github.com/rest/reference/repos#list-organization-repositories") {
        
        Write-Warning "Error loading information from org with name [$orgName], trying with user based repository list"
        $url = "https://api.github.com/users/$orgName/repos"
        $info = CallWebRequest -url $url -userName $userName -PAT $PAT
    }

    Write-Host "Found [$($info.Count)] repositories in [$orgName]"
    return $info
}

function FindRepoOrigin {
    param (
        [string] $repoUrl,
        [string] $userName,
        [string] $PAT
    )
    
    $info = CallWebRequest -url $repoUrl -userName $userName -PAT $PAT
        
    if ($false -eq $info.fork) {
        Write-Error "The repo with url [$repoUrl] is not a fork"
        throw
    }

    Write-Host "Forks default branch = [$($info.parent.default_branch)] [$($info.parent.branches_url)] with last push [$($info.pushed_at)]"
    Write-Host "Found parent [$($info.parent.html_url)] of repo [$repoUrl], last push was on [$($info.parent.pushed_at)]"

    $defaultBranch = $info.parent.default_branch
    $parentDefaultBranchUrl = $info.parent.branches_url -replace "{/branch}", "/$($defaultBranch)"
    Write-Host "Branches url for default branch: " $parentDefaultBranchUrl

    $branchLastCommitDate = GetBranchInfo -PAT $PAT -parent $info.parent.full_name -branchName $defaultBranch

    if ($info.pushed_at -lt $branchLastCommitDate) {
        Write-Host "There are new updates on the parent available on the default branch [$defaultBranch], last commit date: [$branchLastCommitDate]"
    }

    # build the compare url
    $compareUrl = "https://github.com/$($info.full_name)/compare/$defaultBranch..$($info.parent.owner.login):$defaultBranch"
    Write-Host "You can compare the default branches using this link: $compareUrl"

    return [PSCustomObject]@{
        parentUrl = $info.parent.html_url
        defaultBranch = $defaultBranch
        lastPushRepo = $info.pushed_at
        lastPushParent = $branchLastCommitDate
        updateAvailable = ($info.pushed_at -lt $branchLastCommitDate)
        compareUrl = $compareUrl
    }
}

function GetFileAvailable {
    param (
        [string] $repository,
        [string] $fileName,
        [string] $PAT,
        [string] $userName
    )

    $info = GetFileInfo -repository $repository -fileName 'action.yml' -PAT $PAT -userName $userName
    if ($info -eq "https://docs.github.com/rest/reference/repos#get-repository-content") {
        return $false
    }
    else {
        Write-Host "Found yaml file contents!"
        #Write-Host $info
        return $true
    }
}

function CheckAllReposInOrg {
    param (
        [string] $orgName,
        [string] $userName,
        [string] $PAT
    )

    Write-Host "Running a check on all repositories inside of organization [$orgName] with user [$userName] and a PAT that has length [$($PAT.Length)]"

    $repos = FindAllRepos -orgName $orgName -userName $userName -PAT $PAT

    # create hastable
    $reposWithActions = @()

    foreach ($repo in $repos) {
        # add empty line for logs readability
        Write-Host ""

        # check with this call if the repo has a file in the root named 'action.yaml'
        # GET https://api.github.com/repos/rajbos/actions-testing/contents/action.yml
        # https://api.github.com/repos/${$repo.full_name}/contents/action.yml

        $hasActionFile  = GetFileAvailable -repository $repo.full_name -fileName 'action.yaml' -PAT $PAT -userName $userName
        
        if ($hasActionFile) {
            Write-Host "Found action.yaml in repository [$($repo.full_name)], loading readme.md"
            if ($repo.full_name -eq "rajbos/mutation-testing-elements") {
                Write-Host "Break here for testing"
            }
            
            # todo: test for readme.MD / ReadMe.md / README.md / readme.md
            $fileInfo = GetFileInfo -repository $repo.full_name -fileName 'action.yml' -PAT $PAT -userName $userName

            $repoInfo = GetRawFile -url $fileInfo.download_url
            if ($repoInfo) {
                Write-Host "Loaded action.yml information"     
                
                $parsedYaml = ConvertFrom-Yaml $repoInfo

                $repoData = [PSCustomObject]@{
                    repoName = $repo.full_name
                    action = [PSCustomObject]@{
                        name = $parsedYaml["name"]
                        author = $parsedYaml["author"]
                        description = $parsedYaml["description"]
                    }
                }

                $reposWithActions += $repoData
            } 
            else {
                Write-Host "Cannot load action.yml"
            }
        }
        else {
            Write-Host "Skipping repository [$($repo.full_name)] since it has no actions file in the root"
        }
    }

    Write-Host "Found [$($reposWithActions.Count)] repositories with actions"
    return [PSCustomObject]@{
        actions = $reposWithActions
        lastUpdated = Get-Date
    }
}

function GetRawFile {
    param (
        [string] $url
    )

    $result = Invoke-WebRequest -Uri $url -Method Get -ErrorAction Stop | Select-Object -Expand Content

    return $result
}

function UploadActionsDataToGitHub {
    param (
        [object] $actions,
        [string] $marketplaceRepo,
        [string] $userName,
        [string] $PAT
    )
    
    $marketplaceRepoUrl = "https://github.com/$marketplaceRepo.git"
    
    . $PSScriptRoot\git-calls.ps1 -PAT $PAT -$gitUserName $userName `
                                    -RemoteUrl $marketplaceRepoUrl `
                                    -gitUserEmail $userEmail 

    # git checkout
    SetupGit

    # store result on disk
    $actions >> actions-data.json

    CommitAndPushBranch -branchName "data-test"
}

function TestLocally {
    param (
        [string] $orgName,
        [string] $userName,
        [string] $PAT,
        [string] $marketplaceRepo
    )

    # comment line below to skip the reloading of the repos after the first run
    $env:reposWithUpdates = $null
    # load the repos with updates if we don't have them available yet
    if($null -eq $env:reposWithUpdates) {
        $repos = CheckAllReposInOrg -orgName $orgName -userName $userName -PAT $PAT
        $env:reposWithUpdates = $repos | ConvertTo-Json        
    }

    if ($env:reposWithUpdates) {
        Write-Host "Found [$(($env:reposWithUpdates | ConvertFrom-Json).actions.Length)] action repos!"
        UploadActionsDataToGitHub -actions $env:reposWithUpdates -marketplaceRepo $marketplaceRepo -userName $userName -PAT $PAT

        CleanupGit
    }
}

# uncomment to test locally
$orgName = "rajbos-actions"; $userName = "xxx"; $PAT = $env:GitHubPAT; $testingLocally = $true; 
$marketplaceRepo = "rajbos/actions-marketplace"; $userEmail = "raj.bos@gmail.com"; $userName = "Rob Bos";

# main function calls

if ($testingLocally) {
    TestLocally -orgName $orgName -userName $userName -PAT $PAT -marketplaceRepo $marketplaceRepo
}
else {
    # production flow:

    # install a yaml parsing module
    Install-Module powershell-yaml -Scope CurrentUser -Force

    # get action repos
    $reposWithActions = CheckAllReposInOrg -orgName $orgName -userName $userName -PAT $PAT -marketplaceRepo $marketplaceRepo

    if ($reposWithActions.Count -gt 0) {
        Write-Host "Found [$(($reposWithActions | ConvertFrom-Json).actions.Length)] action repos!"
        UploadActionsDataToGitHub -actions $$reposWithActions -marketplaceRepo $marketplaceRepo -userName $userName -PAT $PAT

        Write-Host "Cleaning up local Git folder"
        CleanupGit   
    }
}
