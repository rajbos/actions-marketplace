# example calls:
# .\load-used-actions.ps1 -orgName "rajbos-actions" -userName "xxx" -PAT $env:GitHubPAT -$marketplaceRepo "rajbos/actions-marketplace"
param (
    [string] $orgName,
    [string] $userName,
    [string] $PAT,
    [string] $marketplaceRepo,
    [string] $userEmail
)

# pull in central calls library
. $PSScriptRoot\github-calls.ps1

# install a yaml parsing module
if($env:computername -ne "ROB-XPS9700") {
    Install-Module powershell-yaml -Scope CurrentUser -Force
}

function  GetActionsFromWorkflow {
    param (
        [string] $workflow
    )

    # parse the workflow file and extract the actions used in it
    $parsedYaml = ConvertFrom-Yaml $workflow

    # create hastable
    $actions = @()

    # go through the parsed yaml
    foreach ($job in $parsedYaml["jobs"].GetEnumerator()) {
        Write-Host "  Job found: [$($job.Key)]"
        $steps=$job.Value.Item("steps")
        foreach ($step in $steps) {
            $uses=$step.Item("uses")
            if ($null -ne $uses) {
                Write-Host "   Found action used: [$uses]"
                $action = $uses.Split("@")[0]
                $actions += $action
            }
        }
    }

    return $actions
}

function GetAllUsedActionsFromRepo {
    param (
        [string] $repo,
        [string] $PAT,
        [string] $userName
    )


    $url = "https://api.github.com/repos/$repo"
    $repoInfo = CallWebRequest -url $url -userName $userName -PAT $PAT 
    Write-Host "Repo Info: $repoInfo"

    # get all the actions from the repo
    $workflowFiles = GetAllFilesInPath -repository $repo -path ".github/workflows/" -PAT $PAT -userName $userName
    if ($workflowFiles -eq "https://docs.github.com/rest/reference/repos#get-repository-content") {
    #if ([bool]($workflowFiles.PSobject.Properties.name -match "message")) {
        Write-Host "Could not get workflow files from [$repo]"
        return;
    }
    
    # create hastable to store the results in
    $actionsInRepo = @()

    foreach ($workflowFile in $workflowFiles) {
        if ($workflowFile.download_url.EndsWith(".yml")) { 
            $workflow = GetRawFile -url $workflowFile.download_url -PAT $PAT
            $actions = GetActionsFromWorkflow -workflow $workflow

            $actionsInRepo += $actions
        }
    }

    return $actionsInRepo
}

function LoadAllUsedActionsFromRepos {
    param (
        [object] $repos,
        [string] $userName,
        [string] $PAT,
        [string] $marketplaceRepo
    )

    # create hastable
    $actions = @()
    foreach ($repo in $repos) {
        $actionsUsed = GetAllUsedActionsFromRepo -repo $repo.full_name -PAT $PAT -userName $userName

        $actions += $actionsUsed
    }

    $uniqueActions  = $actions | Sort-Object | Get-Unique -AsString
    Write-Host "Found [$($uniqueActions.Count)] actions in [$($repos.Count)] repos"

    return $uniqueActions
}

function main() {

    # get all repos in an org
    $repos = FindAllRepos -orgName $orgName -userName $userName -PAT $PAT

    # get actions from the workflows in the repos
    $actionsFound = LoadAllUsedActionsFromRepos -repos $repos -userName $userName -PAT $PAT -marketplaceRepo $marketplaceRepo

    if ($actionsFound.Count -gt 0) {

        Write-Host "Found these actions:"
        Write-Host $actionsFound

        # upload the data into the marketplaceRepo
        #Write-Host "Found [$($actionsFound.actions.Length)] actions in use!"

        # todo: store the json file
        #UploadActionsDataToGitHub -actions $actionsFound -marketplaceRepo $marketplaceRepo -PAT $PAT -repositoryName $repositoryName -repositoryOwner $repositoryOwner
    }

}

main