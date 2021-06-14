
# placeholder for caching headers
$CentralHeaders
function Get-Headers {
    param (        
        [string] $userName,
        [string] $PAT
    )

    if ($null -ne $CentralHeaders) {
        return $CentralHeaders
    }

    $pair = "$($userName):$($PAT)"
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
    $basicAuthValue = "Basic $encodedCreds"

    $CentralHeaders = @{
        Authorization = $basicAuthValue
    }

    return $CentralHeaders
}

function CallWebRequest {
    param (
        [string] $url,
        [string] $userName,
        [string] $PAT,
        [string] $verbToUse = "Get",
        [object] $body,
        [boolean] $skipWarnings = $false
    )

    $Headers = Get-Headers -userName $userName -PAT $PAT

    try {

        $bodyContent = ($body | ConvertTo-Json) -replace '\\', '\'
        $result = Invoke-WebRequest -Uri $url -Headers $Headers -Method $verbToUse -Body $bodyContent -ErrorAction Stop
        
        Write-Host "  StatusCode: $($result.StatusCode)"
        Write-Host "  RateLimit-Limit: $($result.Headers["X-RateLimit-Limit"])"
        Write-Host "  RateLimit-Remaining: $($result.Headers["X-RateLimit-Remaining"])"
        Write-Host "  RateLimit-Reset: $($result.Headers["X-RateLimit-Reset"])"
        Write-Host "  RateLimit-Used: $($result.Headers["x-ratelimit-used"])"
        # convert the response json content
        $info = ($result.Content | ConvertFrom-Json)
    }
    catch {
        $messageData = $_.ErrorDetails.Message | ConvertFrom-Json
        if ($false -eq $skipWarnings) {
            Write-Host "Error calling api at [$url]:"
            Write-Host "  StatusCode: $($_.Exception.Response.StatusCode)"
            Write-Host "  RateLimit-Limit: $($_.Exception.Response.Headers.GetValues("X-RateLimit-Limit"))"
            Write-Host "  RateLimit-Remaining: $($_.Exception.Response.Headers.GetValues("X-RateLimit-Remaining"))"
            Write-Host "  RateLimit-Reset: $($_.Exception.Response.Headers.GetValues("X-RateLimit-Reset"))"
            Write-Host "  RateLimit-Used: $($_.Exception.Response.Headers.GetValues("x-ratelimit-used"))"
            
            Write-Host "$($_.ErrorDetails.Message)"
            if ($messageData.message.StartsWith("API rate limit exceeded")) {
                Write-Error "Rate limit exceeded. Halting execution"
                throw
            }
            
            Write-Host "$messageData"
        }
        if ($messageData.message -eq "Not Found") {
            if ($false -eq $skipWarnings) {
                Write-Warning "Call to GitHub Api [$url] had [not found] result with documentation url [$($messageData.documentation_url)]"
            }
            return $messageData.documentation_url
        }
    }

    return $info
}

function GetForkCloneUrl {
    param (
        [string] $forkUrl,
        [string] $PAT
    )

    return "https://xx:$PAT@github.com/$fork.git"
}

function GetParentInfo {
    param (
        [string] $fork,
        [string] $PAT
    )

    $repoUrl = "https://api.github.com/repos/$fork"
    $info = CallWebRequest -url $repoUrl -userName $userName -PAT $PAT

    if ($false -eq $info.fork) {
        Write-Error "Repo [$fork] is not a fork"
        throw
    }

    return [PSCustomObject]@{
        parentUrl = $info.parent.git_url
        parentDefaultBranch = $info.parent.default_branch
    }

}

function GetFileInfo {
    param (
        [string] $repository,
        [string] $fileName,
        [string] $userName,
        [string] $PAT
    )

    Write-Host "Checking if the file [$fileName] exists in repository [$repository]"
    $url = "https://api.github.com/repos/$repository/contents/$fileName"
    $info = CallWebRequest -url $url -userName $userName -PAT $PAT -skipWarnings $true

    return $info
}

function GetBranchInfo {
    param (
        [string] $parent,
        [string] $PAT,
        [string] $branchName
    )

    $repoUrl = "https://api.github.com/repos/$parent/branches/$branchName"
    $info = CallWebRequest -url $repoUrl -userName $userName -PAT $PAT

    return $info.commit.commit.author.date
}

function AddCommentToIssue {
    param (
        [string] $repoName,
        [string] $message,
        [int] $number,
        [string] $userName,
        [string] $PAT
    )

    $url = "https://api.github.com/repos/$repoName/issues/$number/comments"

    $body = [PSCustomObject]@{
        body = $message
    }

    CallWebRequest -url $url -userName $userName -PAT $PAT -body $body -verbToUse "POST"
}


function CloseIssue {
    param (
        [string] $issuesRepositoryName,
        [int] $number,
        [string] $userName,
        [string] $PAT
    )    

    $url = "https://api.github.com/repos/$issuesRepositoryName/issues/$number"

    $data = [PSCustomObject]@{       
        state = "closed"
    }

    Write-Host "Closing issue with number [$number] in repository [$issuesRepositoryName]"
    $result = CallWebRequest -url $url -verbToUse "POST" -body $data -PAT $PAT -userName $userName

    Write-Host "Issue has been closed and can be found at this url: ($($result.html_url))"
}


function CreateNewIssueForRepo { 
    param (
        [Object] $repoInfo,
        [string] $issuesRepositoryName,
        [string] $title,
        [string] $body,
        [string] $PAT,
        [string] $userName
    )

    $url = "https://api.github.com/repos/$issuesRepositoryName/issues"

    $data = [PSCustomObject]@{
        title = $title
        body = $body
    }

    Write-Host "Creating a new issue with title [$title] in repository [$issuesRepositoryName]"
    $result = CallWebRequest -url $url -verbToUse "POST" -body $data -PAT $PAT -userName $userName

    Write-Host "Issue has been created and can be found at this url: ($($result.html_url))"
}

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