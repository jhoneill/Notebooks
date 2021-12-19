#If in a default location, jump to the WindowsPowershell dir . Add it to the path, note if we are running "as admin".
$psDir                     = Join-path ([System.Environment]::GetFolderPath( [System.Environment+SpecialFolder]::MyDocuments)) "\windowsPowershell"
Set-Item -Path "Env:\PATH" (".;$psDir\;"+(Get-Content "ENV:\PATH"))  #Linux is case sensitive and uses "PATH"; windows isnt and uses "Path".
if ($pwd.Path -eq $env:USERPROFILE -or $pwd.path -eq $PSHOME -or $pwd.path -match "^C:\\Windows")    {Set-Location -Path $psdir}
if ($env:PSModulePath -notmatch [regex]::Escape($psDir)) { $env:PSModulePath += ";$psDir\Modules" }
if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value -contains "S-1-5-32-544") {$env:isadmin = $true}

#region functions & aliases cd, cd-, whathas, howlong,
class PathTransformAttribute : System.Management.Automation.ArgumentTransformationAttribute  {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
        switch -regex ($InputData) {
            "^=+"       {return ($inputData -replace "^=+", (Get-Location -Stack).ToArray()[$Matches[0].Length -1].Path); break}
            "^\^"       {return ($inputData -replace "^\^", $PSScriptRoot)                              ; break }
            "^\\\*|/\*" {return ($pwd.path  -replace "^(.*$($InputData.substring(2)).*?)[/\\].*$",'$1') ; break }
            "^\.{3}"    {return ($InputData -replace "(?<=^\.[.\\]*)(?=\.{2,}(\\|$))",  ".\")           ; break}
        }
        return ($InputData)
    }
}
class ValidatePathAttribute  : System.Management.Automation.ValidateArgumentsAttribute {
    [string]$Exemption = "" #"^-+$"
    [boolean]$ContainersOnly = $false
    [int]$MaxItems = -1
    [void] Validate([object] $arguments , [System.Management.Automation.EngineIntrinsics]$EngineIntrinsics) {
        if ($this.Exemption -and $arguments -match $this.Exemption) {return}                    #Exempt some things eg  "-"" or "----""
        elseif ($arguments -match "^(\w+):\\?" -and (Get-PSDrive $Matches[1] -ErrorAction SilentlyContinue) ) {return}    #Allow drives
        else {
            if ($this.ContainersOnly) {$count = (Get-Item -Path $arguments -Force -ErrorAction SilentlyContinue).where({$_.psIscontainer}).count}
            else                      {$count = (Get-Item -Path $arguments -Force -ErrorAction SilentlyContinue).count }
            if ($count -eq 0 -and $this.maxitems -ge 0) {
                throw [System.Management.Automation.ValidationMetadataException]::new("'$arguments' does not exist.")
            }
            elseif ($this.Maxitems -ge 0 -and $count -gt $this.maxitems) {
                throw  [System.Management.Automation.ValidationMetadataException]::new("'$arguments' resolved to multiple $count items. Maximum allowed is $($this.Maxitems)")
            }
         }
         return
    }
}
class PathCompleter          : System.Management.Automation.IArgumentCompleter {
    [System.Collections.Generic.IEnumerable[System.Management.Automation.CompletionResult]] CompleteArgument(
        [string]$CommandName, [string]$ParameterName, [string]$WordToComplete,
        [System.Management.Automation.Language.CommandAst]$CommandAst, [System.Collections.IDictionary] $FakeBoundParameters
    )
    {
        $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
        $dots    = [regex]"^\.\.(\.*)(\\|$|/)" #find two dots, any more dots (captured), followed by / \ or end of string
        $sep     = [system.io.path]::DirectorySeparatorChar
        $wtc     = ""
        switch -regex ($wordToComplete) {
            #.. alone doesn't expand,  expand  .. followed by n dots (and possibly \ or /)  to ..\ n+1 times
            $dots       {$newPath = "..$Sep" * (1 + $dots.Matches($wordToComplete)[0].Groups[1].Length)
                         $wtc = $dots.Replace($wordtocomplete,$newPath) ; break }
            "^\^"       {$wtc = $wordtocomplete -replace "^\^", $PSScriptRoot      ; break }  # ^ [tab] ==> PS profile dir
            "^\.$"      {$wtc = ""                                      ; break }  # . and ~ alone don't expand.
            "^~$"       {$wtc = $env:USERPROFILE                        ; break }
            #for 1 = sign tab through the location stack.
            "^=$"       { foreach ($stackPath in (Get-Location -Stack).ToArray().Path) {
                            if ($stackpath -match "[ ']") {$stackpath = '"' + $stackPath + '"'}
                            $results.Add([System.Management.Automation.CompletionResult]::new($stackPath))
                          }
                          return $results ; continue
                        }
            #replace string of = signs with the item that many up the location stack
            "^=+$"      {$wtc = (Get-Location -Stack).ToArray()[$wordToComplete.Length -1].Path  ; continue }
            #if path is c:\here\there\everywhere\stuff convert "\*the"  to "c:\here\there"
            "^\\\*|/\*" {$wtc = $pwd.path -replace "^(.*$($WordToComplete.substring(2)).*?)[/\\].*$",'$1' ; continue }
            default     {$wtc = $wordToComplete}
        }
        foreach ($result in [System.Management.Automation.CompletionCompleters]::CompleteFilename($wtc) ) {
             if ($result.resultType -eq "ProviderContainer" -or  $CommandName -notin @("cd","dir")) {$results.Add($result)}
        }
        foreach ($result in $Global:ExecutionContext.SessionState.Drive.GetAll().name -like "$wordTocomplete*") {
                 $results.Add([System.Management.Automation.CompletionResult]::new("$result`:"))
        }
        return   $results
    }
}
$sb =  {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $pc = [pathcompleter]::new()
    $pc.CompleteArgument($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
}
Register-ArgumentCompleter -CommandName Copy-Item     -ParameterName Path        -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Copy-Item     -ParameterName Destination -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Move-Item     -ParameterName Path        -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Move-Item     -ParameterName Destination -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Remove-Item   -ParameterName Path        -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Get-ChildItem -ParameterName Path        -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Get-Content   -ParameterName Path        -ScriptBlock $sb
Register-ArgumentCompleter -CommandName Start-Process -ParameterName Path        -ScriptBlock $sb

#redefine cd as a proxy for push location (and cd- for Pop). Argument transformer makes cd ... into cd ..\.. (extra dot = extra level)
Set-Alias -Name "cd-" -Value Pop-Location
Remove-Item -Path Alias:\cd -ErrorAction SilentlyContinue
function cd   {
    <#
        .ForwardHelpTargetName Microsoft.PowerShell.Management\Push-Location
        .ForwardHelpCategory Cmdlet
    #>
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(ParameterSetName='Path', Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [PathTransform()]
        [ArgumentCompleter([PathCompleter])]
        [ValidatePath(Exemption="^-+$",ContainersOnly=$true,MaxItems=1)]
        [string]$Path,

        [Parameter(ParameterSetName='LiteralPath', ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath','LP')]
        [string]$LiteralPath,

        [switch]$PassThru,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$StackName
    )
    process {
        if ($Path -match "^-+$") {foreach ($i in (1..$Path.Length)) {Pop-Location }}
        elseif ($Path -or $LiteralPath)          {Push-Location @PSBoundParameters }
    }
}
function cd.. {Push-Location -Path ..}
function cd\  {Push-Location -Path \ }
function cd~  {Push-Location -Path ~ }

function WhatHas {
   <#
        .Synopsis
            Searches scripts (or other files) for text
        .Description
            Searches specified files for text (optionally searching through subdirectories).
        .Parameter Pattern
            What should be sought, can be piped into the command.
        .Parameter Recurse
            If specified subdirectories will be searched; if not, only the the current folder is tried
        .Parameter Include
            The files to searched, .PS1 by default
        .Parameter List
            Returns only the first match in each input file. By default a MatchInfo Object is returned for each match
    #>
    param   (
        [Parameter(ValueFromPipeLine=$true,Mandatory=$true)]$Pattern,
        [PathTransform()]
        [ArgumentCompleter([PathCompleter])]
        [parameter(ValueFromPipelineByPropertyName = $true)][Alias('Fullname','Path')]
        $Include=@("*.ps1","*.js","*.sql"),
        [Switch]$Recurse,
        [Switch]$List,
        [Switch]$BareMatch
    )
    Process {
        write-debug "Checking $include for $Pattern"
        $match = $(if ($Recurse) { Get-ChildItem -Recurse -Include $include} else { Get-ChildItem  $include} ) |
                        Select-String -Pattern $pattern  -List:$list
        if ($BareMatch) { $match | ForEach-Object {$_.matches} | ForEach-Object {$_.value} }
        else            { $match }
    }
}

function HowLong {
    <#
        .Synopsis
            Returns the time taken to run a command
        .Description
            By default returns the time taken to run the last command
        .Parameter ID
            The history ID of an earlier item.
    #>
    param   ([Parameter(ValueFromPipeLine=$true)]$Id =  ($MyInvocation.HistoryId -1))
    process { foreach ($i in $Id) { (Get-History -Id $i -Count 1 ).EndExecutionTime.Subtract((Get-History -Id $i -Count 1).StartExecutionTime).TotalSeconds } }
}

if ($PSStyle) {
    $PSStyle.Formatting.TableHeader   = $null
    $PsStyle.Formatting.FormatAccent  = $null
}
if ($host.name -match '^\.NET Interactive') {
    $host.ui.rawui.set_WindowSize( ([System.Management.Automation.Host.Size]::new(175,50)) )
}
