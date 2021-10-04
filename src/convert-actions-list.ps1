$filename = "used-actions.json"
$actions = Get-Content $filename | ConvertFrom-Json

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

Write-Host ($summarized | ConvertTo-Json -Depth 10)