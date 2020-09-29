$Script:WinPSTtemplate = @"
{{
    "metadata": {{
        "kernelspec": {{
            "name": "powershell",
            "display_name": "PowerShell"
        }},
        "language_info": {{
            "name": "powershell",
            "codemirror_mode": "shell",
            "mimetype": "text/x-sh",
            "file_extension": ".ps1"
        }}
    }},
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells": [
        {0}
    ]
}}
"@
$Script:DotNetPSTemplate = @"
{{
    "metadata": {{
        "kernelspec": {{
            "name":         ".net-powershell",
            "display_name": ".NET (PowerShell)",
            "language":     "PowerShell"
        }},
        "language_info": {{
            "name":           "Powershell",
            "pygments_lexer": "powerShell",
            "mimetype":       "text/x-powershell",
            "file_extension": ".ps1",
            "version":         "7.0"
        }}
    }},
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells": [
        {0}
    ]
}}
"@

class PSNotebookRunspace {
    <#
        .SYNOPSIS

        .Example
    #>
    $Runspace
    $PowerShell

    PSNotebookRunspace() {
        $this.Runspace = [runspacefactory]::CreateRunspace()
        $this.PowerShell = [powershell]::Create()
        $this.PowerShell.runspace = $this.Runspace
        $this.Runspace.Open()
    }

    [object]Invoke($code) {
        $this.PowerShell.AddScript([scriptblock]::Create($code))
        $null = $this.PowerShell.AddCommand("Out-String")
        return $this.PowerShell.Invoke()
    }

    [void]Close() {
        $this.Runspace.Close()
    }
}

function New-PSNotebookRunspace {
    <#
        .SYNOPSIS
        New-PSNotebookRunspace instantiates the PSNotebookRunspace

        .Example
        New-PSNotebookRunspace
    #>
    [PSNotebookRunspace]::new()
}

function Add-NotebookCode {
    <#
        .SYNOPSIS
        Add-NotebookCode adds PowerShell code to a code block

        .Description
        Add-NotebookCode is intended to be used in a New-PSNotebook scriptblock

        .Example
        New-PSNotebook -AsText {
            Add-NotebookCode -code 'Hello World'
        }

        "cells": [{
            "cell_type": "code",
            "source": "Hello World",
            "metadata": {
                "azdata_cell_guid": "4c8b5648-af44-433b-8bf9-f0b6ca975b2b"
            },
            "outputs": [{
                "name": "stdout",
                "output_type": "stream",
                "text": ""
            }]
        }]

    #>
    [cmdletbinding(DefaultParameterSetName="Default")]
    [Alias("Code")]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $Code,
        [Parameter(ParameterSetName="Default",Position=1)]
        $OutputText = "",
        [Parameter(ParameterSetName="OutputObject")]
        $DispayData,
        [switch]$NoGUID
    )
    <# Magic commands
        #!Pwsh - removed,
        #!ExcludeResults (or #  Exclude  Results or similar) don't run the code.
        #!About give OS and PS Versions. and don't run anything else in the cell
        #!Time - if there will be output, start a stopwatch, run the code, add the time to the output.
    #>
    $code =     $code -replace "(?i)^#!pwsh\s*"
    if     (    $code -match   "^(?i)#!?\s*exclude\s*results") {
                $code = $code -replace $pattern, ""
    }
    elseif (    $code -match   "^(?i)#!about" -and $script:IncludeCodeResults ) {
         $OutputText = -join $Script:PSNotebookRunspace.invoke('"PowerShell $($psversiontable.psversion) on $([System.environment]::MachineName), $([System.Environment]::OSVersion.VersionString)"')
    }
    elseif (    (-not $DispayData)            -and $script:IncludeCodeResults ) {
            if ($code -match "^(?i)#!time") {
                $sw = [System.Diagnostics.Stopwatch]::new()
                $sw.Start()
            }

            $outputText = -join $Script:PSNotebookRunspace.Invoke($code)

            if ($code -match "^(?i)#!time") {
                $sw.Stop()
                $OutputText += "`nWall time {0:n0}ms" -f  $sw.Elapsed.TotalMilliseconds
            }
    }

    <#Build the cell
      - add DisplayData if provided with a structure to go into outputs
      - or if DisplayData wasn't given and IncludeCodeResults is set we may have output text.
           Output that as a 'stream' type.
     - Add a GUID used by AzureDataStudio unless told not to
     - And return everything as JSON
    #>
    $newBlock  = [Ordered]@{
        'cell_type' = 'code'
        'source'    = @($code)
        'metadata'  = @{}
        'outputs'   = @()
    }
    if     ($outputText)  {
        $newBlock['outputs'] += @{
            "output_type" = "stream"
            "name"        = "stdout"
            "text"        = $outputText
        }
        Write-Verbose $outputText
    }
    elseif ($DispayData)  {
        $newBlock.ouputs += @{
            "output_type" = "display_data"
            'metadata'    = [PSCustomObject]@{ }
            "data"        = $DispayData
        }
    }
    if     (-not $NoGUID) {
        $newblock.metadata['azdata_cell_guid'] = (New-Guid).Guid
    }

    $script:codeBlocks += $newBlock | ConvertTo-Json -Depth 4
}

function Add-NotebookMarkdown {
    <#
        .SYNOPSIS
        Add-NotebookMarkdown adds Markdown to a markdown block

        .Description
        Add-NotebookMarkdown is intended to be used in a New-PSNotebook scriptblock

        .Example

        New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
        }

        {
            "metadata": {
                "kernelspec": {
                    "name": "powershell",
                    "display_name": "PowerShell"
                },
                "language_info": {
                    "name": "powershell",
                    "codemirror_mode": "shell",
                    "mimetype": "text/x-sh",
                    "file_extension": ".ps1"
                }
            },
            "nbformat_minor": 2,
            "nbformat": 4,
            "cells": [{
                "cell_type": "markdown",
                "source": "# This is a H1 tag"
            }]
        }
    #>
    [Alias("Markdown")]
    param($markdown)

    $script:codeBlocks += [PSCustomObject][Ordered]@{
        'cell_type' = 'markdown'
        'metadata'  = [PSCustomObject]@{ }
        'source'    = @($markdown)
    } | ConvertTo-Json -Compress
}

function New-PSNotebook {
    <#
        .SYNOPSIS
        Creates a new PowerShell Notebook that can be returned as text or saves as a `ipynb` file.

        .Description
        New-PSNotebook takes a script block in which these two functions can be be use to contstruct a PowerShell Notebook `Add-NotebookMarkdown`, `Add-NotebookCode`.
        Additionally, you can use the `-IncludeCodeResults` switch to execute the PowerShell code and include the results in the notebook.
        It will create a clean runspace for this unless -RunSpace is provided.
        By default the notebook uses the Jupyer Kernel named "powershell" provided with Azure Data Studio,
        but the switch -DotNetInteractive (alias -DNI) will build a notebook for DotNetInteractive.

        .Example
        # creates a new notebook, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, executes the PowerShell then includes it the block, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook -IncludeCodeResults {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, and returns it as text

        New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        {
            "metadata": {
                "kernelspec": {
                    "name": "powershell",
                    "display_name": "PowerShell"
                },
                "language_info": {
                    "name": "powershell",
                    "codemirror_mode": "shell",
                    "mimetype": "text/x-sh",
                    "file_extension": ".ps1"
                }
            },
            "nbformat_minor": 2,
            "nbformat": 4,
            "cells": [{
                "cell_type": "markdown",
                "source": "# This is a H1 tag"
            }, {
                "cell_type": "code",
                "source": "Hello World",
                "metadata": {
                    "azdata_cell_guid": "a7b91b6c-f57f-4d57-8cc4-7773d7f22756"
                },
                "outputs": [{
                    "name": "stdout",
                    "output_type": "stream",
                    "text": ""
                }]
            }]
        }
        .Example
        # read an existing notebook run its code against a remote session, and output the results to a new notebook

        PS > $pssession =  New-PSSession -ComputerName $computername
        PS > New-PSNotebook {
            Add-NotebookMarkdown   "# Run Remotely on $computername"
            switch (Get-NotebookContent  .\datademo.ipynb) {
               { $_.Type -eq 'markdown' } { Add-NotebookMarkdown  $_.Source }
               { $_.Type -eq 'code'     } { Add-NotebookCode      $_.source -Verbose }
            }} -IncludeCodeResults  -DNI  "$computerName.ipynb" -RunSpace $pssession.Runspace
    #>
    [alias("Notebook")]
    param(
        [Scriptblock]$sb,
        $NoteBookName,
        [Switch]$AsText,
        [Switch]$IncludeCodeResults,
        [alias("DNI")]
        [switch]$DotNetInteractive,
        $RunSpace
    )

    $script:codeBlocks = @()
    if ($IncludeCodeResults) {
        $Script:IncludeCodeResults = $IncludeCodeResults
        if (-not $RunSpace) {$Script:PSNotebookRunspace = New-PSNotebookRunspace}
        else {
            if ($RunSpace.psobject.Members.name -notcontains "invoke") {
                Add-Member -InputObject $RunSpace -name PowerShell -MemberType NoteProperty -Value ([powershell]::Create())
                $RunSpace.PowerShell.Runspace = $RunSpace
                Add-Member -InputObject $RunSpace -name invoke -MemberType ScriptMethod -Value {
                   param ($code)
                    $null = $this.PowerShell.AddScript([scriptblock]::Create($code))
                    $null = $this.PowerShell.AddCommand("Out-String")
                    return  $this.PowerShell.Invoke()
                }
            }
            $Script:PSNotebookRunspace = $RunSpace
        }
    }

    &$sb

    if ($DotNetInteractive) {
          $result = $Script:DotNetPSTemplate -f ($script:codeBlocks -join ',')
    }
    else {$result = $Script:WinPSTtemplate   -f ($script:codeBlocks -join ',')}

    $Script:IncludeCodeResults = $false
    if ($Script:PSNotebookRunspace -and -not $RunSpace) {
        $Script:PSNotebookRunspace.Close()
        $Script:PSNotebookRunspace = $null
    }

    if (-not $NoteBookName) {
        return $result
    }
    else {
        if($NoteBookName -notmatch "\.ipynb$") {$NoteBookName  = $NoteBookName  + ".ipynb"}
        $result | Set-Content -Encoding UTF8 -Path $NoteBookName
    }
}

function New-SQLNotebook {
    <#
        .SYNOPSIS
        Creates a new PowerShell Notebook that can be returned as text or saves as a `ipynb` file.

        .Description
        New-PSNotebook takes a script block in which these two functions can be be use to contstruct a PowerShell Notebook `Add-NotebookMarkdown`, `Add-NotebookCode`.
        Additionally, you can use the `-IncludeCodeResults` switch to execute the PowerSHell code and include the results in the notebook.

        .Example
        # creates a new notebook, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, executes the PowerShell then includes it the block, and saves it as TestNotebook.ipynb

        New-PSNotebook -NoteBookName .\TestNotebook -IncludeCodeResults {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        .Example
        # creates a new notebook, and returns it as text

        New-PSNotebook -AsText {
            Add-NotebookMarkdown -markdown "# This is a H1 tag"
            Add-NotebookCode -code 'Hello World'
        }

        {
            "metadata": {
                "kernelspec": {
                    "name": "powershell",
                    "display_name": "PowerShell"
                },
                "language_info": {
                    "name": "powershell",
                    "codemirror_mode": "shell",
                    "mimetype": "text/x-sh",
                    "file_extension": ".ps1"
                }
            },
            "nbformat_minor": 2,
            "nbformat": 4,
            "cells": [{
                "cell_type": "markdown",
                "source": "# This is a H1 tag"
            }, {
                "cell_type": "code",
                "source": "Hello World",
                "metadata": {
                    "azdata_cell_guid": "a7b91b6c-f57f-4d57-8cc4-7773d7f22756"
                },
                "outputs": [{
                    "name": "stdout",
                    "output_type": "stream",
                    "text": ""
                }]
            }]
        }

        .example
        notebook -DNI -IncludeCodeResults -NoteBookName dd2.ipynb  {NotebookContent  .\datademo.ipynb | % {&  $_.Type   $_.Source  -Verbose }}
    #>
    param(
        [Scriptblock]$sb,
        $NoteBookName,
        [Switch]$AsText,
        [Switch]$IncludeCodeResults
    )

    $script:codeBlocks = @()
    if ($IncludeCodeResults) {
        $Script:IncludeCodeResults = $IncludeCodeResults
        $Script:PSNotebookRunspace = New-PSNotebookRunspace
    }

    &$sb

    $result = @"
{
    "metadata": {
        "kernelspec": {
            "name": "sql",
            "display_name": "SQL"
        },
        "language_info": {
            "name": "sql",
            "codemirror_mode": "shell",
            "mimetype": "text/x-sh",
            "file_extension": ".sql"
        }
    },
    "nbformat_minor": 2,
    "nbformat": 4,
    "cells": [
        $($script:codeBlocks -join ',')
    ]
}
"@

    $Script:IncludeCodeResults = $false
    if ($Script:PSNotebookRunspace) {
        $Script:PSNotebookRunspace.Close()
        $Script:PSNotebookRunspace = $null
    }

    if ($AsText) {
        return $result
    }
    else {
        $result | Set-Content -Encoding UTF8 -Path $NoteBookName
    }

}
