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
        Write-Host "Found yml file contents!"
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

        $hasActionFile  = GetFileAvailable -repository $repo.full_name -fileName 'action.yml' -PAT $PAT -userName $userName
        
        if ($hasActionFile) {
            Write-Host "Found action.yml in repository [$($repo.full_name)], loading the file contents"
            if ($repo.full_name -eq "rajbos/mutation-testing-elements") {
                Write-Host "Break here for testing"
            }
                        
            $fileInfo = GetFileInfo -repository $repo.full_name -fileName 'action.yml' -PAT $PAT -userName $userName

            Write-Host "$fileInfo"
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

    Write-Host "Loading file content from url [$url]"
    $result = Invoke-WebRequest -Uri $url -Method Get -ErrorAction Stop | Select-Object -Expand Content

    return $result
}

function UploadActionsDataToGitHub {
    param (
        [object] $actions,
        [string] $marketplaceRepo,
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
        UploadActionsDataToGitHub -actions $env:reposWithUpdates -marketplaceRepo $marketplaceRepo -PAT $PAT

        CleanupGit
    }
}

# uncomment to test locally
#$orgName = "rajbos-actions"; $userName = "xxx"; $PAT = $env:GitHubPAT; $testingLocally = $true; 
#$marketplaceRepo = "rajbos/actions-marketplace"; $userEmail = "raj.bos@gmail.com"; $userName = "Rob Bos";

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
        Write-Host "$reposWithActions"
        Write-Host "Found [$($reposWithActions.actions.Length)] action repos!"
        UploadActionsDataToGitHub -actions $$reposWithActions -marketplaceRepo $marketplaceRepo -PAT $PAT

        Write-Host "Cleaning up local Git folder"
        CleanupGit   
    }
}
