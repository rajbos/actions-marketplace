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

Write-Host "We're running with these parameters:"
Write-Host " PAT.Length: [$($PAT.Length)]"
Write-Host " orgName: [$orgName]"
Write-Host " userName: [$userName]"
Write-Host " marketplaceRepo: [$marketplaceRepo]"
Write-Host " userEmail: [$userEmail]"

# install a yaml parsing module (already done in the container image)
if($env:computername -ne "ROB-XPS9700") {
    Write-Host "PSHOME: [$pshome]" 
    Write-Host "PSModulePath:"
    foreach ($path in $env:PSModulePath -split ':') {
        Write-Host "- [$path]"
    }
    try {
        Write-Host "Importing module for the yaml parsing"
        Import-Module powershell-yaml -Force
    }
    catch {
        Write-Warning "Error during importing of the yaml module needed for parsing"
        Write-Warning $_
    }
}

Set-Location /github/home/.local/share/powershell/Modules
foreach ($item in Get-ChildItem) { 
    Write-Host $item.Name
}

function  GetActionsFromWorkflow {
    param (
        [string] $workflow,
        [string] $workflowFileName,
        [string] $repo
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
                $actionLink = $uses.Split("@")[0]

                $data = [PSCustomObject]@{
                    actionLink = $actionLink
                    workflowFileName = $workflowFileName
                    repo = $repo
                }

                $actions += $data
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

    # get all the actions from the repo
    $workflowFiles = GetAllFilesInPath -repository $repo -path ".github/workflows" -PAT $PAT -userName $userName
    if (([string]$workflowFiles).StartsWith("https://docs.github.com/")) {
        Write-Host "Could not get workflow files from [$repo]"
        return;
    }
    
    # create hastable to store the results in
    $actionsInRepo = @()

    Write-Host "Found [$($workflowFiles.Length)] files in the workflows directory"
    foreach ($workflowFile in $workflowFiles) {
        try {
            if ($null -ne $workflowFile.download_url -and $workflowFile.download_url.Length -gt 0 -and $workflowFile.download_url.Split("?")[0].EndsWith(".yml")) { 
                $workflow = GetRawFile -url $workflowFile.download_url -PAT $PAT
                $actions = GetActionsFromWorkflow -workflow $workflow -workflowFileName $workflowFile.name -repo $repo

                $actionsInRepo += $actions
            }
        }
        catch {
            Write-Warning "Error handling this workflow file:"
            Write-Host $workflowFile | ConvertFrom-Json -Depth 10
            Write-Warning "----------------------------------"
            Write-Host "Error: [$_]"
            Write-Warning "----------------------------------"
        }
    }

    return $actionsInRepo
}

function SummarizeActionsUsed {
    param (
        [object] $actions
    )

    $summarized =  @()
    foreach ($action in $actions) {
        $found = $summarized | Where-Object { $_.actionLink -eq $action.actionLink }
        if ($null -ne $found) {
            # action already found, add this info to it
            $newInfo =  [PSCustomObject]@{
                repo = $action.repo
                workflowFileName = $action.workflowFileName
            }

            $found.workflows += $newInfo
            $found.count++
        }
        else {
            # new action, create a new object
            $newItem =  [PSCustomObject]@{
                actionLink = $action.actionLink
                count = 1
                workflows =  @(
                    [PSCustomObject]@{
                        repo = $action.repo
                        workflowFileName = $action.workflowFileName
                    }
                )           
            }
            $summarized += $newItem
        }
    }

    return $summarized
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
    $i=0
    foreach ($repo in $repos) {
        if ($null -ne $repo -And $repo.full_name.Length -gt 0) {
            Write-Host "Loading actions from repo: [$($repo.full_name)]"
            $actionsUsed = GetAllUsedActionsFromRepo -repo $repo.full_name -PAT $PAT -userName $userName

            $actions += $actionsUsed

            # comment out code below to stop after a certain number of repos to prevent issues with 
            # rate limiting on the load file count (that is not workin correctly)

            #$i++
            #if ($i -eq 2) {
            #    # break out on second result:
            #    return $actions
            #}
        }
    }

    return $actions
}

function main() {

    # get all repos in an org
    $repos = FindAllRepos -orgName $orgName -userName $userName -PAT $PAT

    # get actions from the workflows in the repos
    $actionsFound = LoadAllUsedActionsFromRepos -repos $repos -userName $userName -PAT $PAT -marketplaceRepo $marketplaceRepo

    if ($actionsFound.Count -gt 0) {
                
        $summarizeActions = SummarizeActionsUsed -actions $actionsFound

        Write-Host "Found [$($actionsFound.Count)] actions used in workflows with [$($summarizeActions.Count) unique actions]"

        # write the actions to disk
        $fileName = "summarized-actions.json"
        $jsonObject = ($summarizeActions | ConvertTo-Json -Depth 10)
        New-Item -Path $fileName -Value $jsonObject -Force | Out-Null
        Write-Host "Stored the summarized usage info into this file: [$fileName]"

        # upload the data into the marketplaceRepo
        #Write-Host "Found [$($actionsFound.actions.Length)] actions in use!"

        # todo: store the json file
        #UploadActionsDataToGitHub -actions $actionsFound -marketplaceRepo $marketplaceRepo -PAT $PAT -repositoryName $repositoryName -repositoryOwner $repositoryOwner
    }

    return $summarizeActions
}

$actions = main
return $actions
