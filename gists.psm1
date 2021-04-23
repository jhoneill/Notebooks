function Get-Gist {
    param(
        [Parameter(ParameterSetName='User')]
        $User,
        [Parameter(ParameterSetName='Gist',Mandatory=$true)]
        $Gist,
        [Parameter(ParameterSetName='Gist')]
        $Destination,
        $Token
    )
    if ($Gist) {
        if ($Destination -and -not (Test-Path -PathType Container $Destination)) {
            Write-Warning "$Destination is not a valid directory." ; return
        }
        $params = @{
            Method  = 'GET'
            Uri     = $Gist  -replace '^.*([a-f,0-9]{32})$' ,'https://api.github.com/gists/$1'
        }
    }
    elseif ($user) {
        $params = @{
            Method  = 'GET'
            Uri     = "https://api.github.com/users/$User/gists"
        }
    }
    else {
        if     (-not $Token -and (Test-Path env:github_token)) {$Token = $env:github_token}
        elseif (-not $Token -and $PSVersionTable.Platform -like "win*") {
            try     {$Token = & (Join-Path $PSScriptRoot 'Get-CredentialFromWindowsCredentialManager.ps1') -TargetName git:https://github.com -PlainTextPasswordOnly }
            catch   {throw "Could not read stored access token and env:github_token not set. You need to set it to a GitHub PAT"}
        }
        elseif (-not $Token) { throw "env:github_token not set. You need to set it to a GitHub PAT"}
        $params = @{
            Method  = 'GET'
            Uri     = 'https://api.github.com/gists'
            Headers = @{"Authorization" = "token $token" }
        }
    }
    $results = Invoke-RestMethod @params
    if ($Destination) {
        $results.files | Get-Member -MemberType NoteProperty | ForEach-Object {$results.files.($_.name)} |
            ForEach-Object {$_.content | Out-File -path (Join-Path $Destination $_.filename) }
    }
    else {
        $results | Select-Object html_url,
                                 @{n='Owner';    e={$_.owner.login}},
                                 @{n='fileList'; e={$_.files.psobject.Properties.name -join ", "}},
                                 created_at, Updated_at, public, description, files, url,
                                 @{n='fileUrls'; e={foreach ($p in ($_.files | Get-Member -MemberType NoteProperty).Name) {$_.files.$p.raw_url} }  }
    }
}

function Update-Gist {
    param(
        [Parameter(Mandatory=$true)]
        $Gist,
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        $Path,
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=0)]
        $Contents,
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=1)]
        [alias('Name')]
        $FileName,
        [switch]$Show
    )
    begin    {
        if (Test-Path env:github_token) {$token = $env:github_token}
        elseif ($PSVersionTable.Platform -like "win*") {
            try   {$token = & (Join-Path $PSScriptRoot 'Get-CredentialFromWindowsCredentialManager.ps1') -TargetName git:https://github.com -PlainTextPasswordOnly }
            catch {throw "Could not read stored access token and env:github_token not set. You need to set it to a GitHub PAT"}
        }
        else { throw "env:github_token not set. You need to set it to a GitHub PAT"}
        $params = @{
            Method  = 'Patch'
            Uri     = $Gist  -replace '^.*([a-f,0-9]{32})$' ,'https://api.github.com/gists/$1'
            Headers = @{"Authorization" = "token $token" }
        }
    }
    process  {
        if ($PSBoundParameters.ContainsKey('Path')) {
            $Contents = Get-content $Path -Encoding utf8
            if (-not $FileName) {$FileName = Split-Path -Leaf $Path}
        }
        $gist = @{
            'files'       = @{
                "$($FileName)" = @{
                    'content' = "$($Contents)"
                }
            }
        }
        $result = Invoke-RestMethod @params -Body ($gist | ConvertTo-Json -EscapeHandling EscapeNonAscii)
        if ($Show) {Start-Process $result.html_url}
        else       {return        $result.html_Url}
    }
}

function Remove-Gist {
    [cmdletbinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
    param(
        [Parameter(Mandatory=$true)]
        $Gist,
        [switch]$force
    )
    begin    {
        if (Test-Path env:github_token) {$token = $env:github_token}
        elseif ($PSVersionTable.Platform -like "win*") {
            try   {$token = & (Join-Path $PSScriptRoot 'Get-CredentialFromWindowsCredentialManager.ps1') -TargetName git:https://github.com -PlainTextPasswordOnly }
            catch {throw "Could not read stored access token and env:github_token not set. You need to set it to a GitHub PAT"}
        }
        else { throw "env:github_token not set. You need to set it to a GitHub PAT"}
        $params = @{
            Method  = 'Delete'
            Headers = @{"Authorization" = "token $token" }
        }
    }
    process  {
        $params['Uri']   = $Gist  -replace '^.*([a-f,0-9]{32})$' ,'https://api.github.com/gists/$1'
        if ($force -or $PSCmdlet.ShouldProcess($gist,'Delete Gist')) {
          $null = Invoke-RestMethod @params
        }
    }
}

function New-Gist {
    param(
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        $Path,
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=0)]
        $Contents,
        [Parameter(ParameterSetName='File',ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory,ParameterSetName='TwoStrings',Position=1)]
        [alias('Name')]
        $FileName,
        $Description ,
        [switch]$Public,
        [switch]$Show
    )
    begin    {
        if (Test-Path env:github_token) {$token = $env:github_token}
        elseif ($PSVersionTable.Platform -like "win*") {
            try   {$token = & (Join-Path $PSScriptRoot 'Get-CredentialFromWindowsCredentialManager.ps1') -TargetName git:https://github.com -PlainTextPasswordOnly }
            catch {throw "Could not read stored access token and env:github_token not set. You need to set it to a GitHub PAT"}
        }
        else { throw "env:github_token not set. You need to set it to a GitHub PAT"}
        $params = @{
            Method  = 'Post'
            Uri     = 'https://api.github.com/gists'
            Headers = @{"Authorization" = "token $token" }
        }
    }
    process  {
        if ($PSBoundParameters.ContainsKey('Path')) {
            $Contents = Get-content $Path -Encoding utf8
            if (-not $FileName) {$FileName = Split-Path -Leaf $Path}
        }
        $gist = @{
            'public'      = ($Public -as [bool])
            'files'       = @{
                "$($FileName)" = @{
                    'content' = "$($Contents)"
                }
            }
        }
        if ($Description) {$gist['description'] = $Description}
        $result  = Invoke-RestMethod @params -Body ($gist | ConvertTo-Json -EscapeHandling EscapeNonAscii)
        if ($Show) {Start-Process $result.html_url}
        else       {return        $result.html_Url}
    }
}
