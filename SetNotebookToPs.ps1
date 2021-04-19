param (
    [Parameter(ValueFromPipeline = $true)]
    $Path,
    $OutputPath,
    [switch]$FixOutput
)
process {
    $nb = Get-Content $Path | ConvertFrom-Json -Depth 10
    $nb.metadata.kernelspec.language            = 'PowerShell'         # "C#"            / "F#"
    $nb.metadata.kernelspec.name                = '.net-powershell'    # ".net-csharp"   / ".net-fsharp"
    $nb.metadata.kernelspec.display_name        = '.NET (PowerShell)'  # ".NET (C#)"     / ".NET (F#)"
    $nb.metadata.language_info.file_extension   = '.ps1'               # ".cs"           / "".fs"
    $nb.metadata.language_info.mimetype         = 'text/x-powershell'  # "text/x-csharp" / "text/x-fsharp"
    $nb.metadata.language_info.name             = 'PowerShell'         # "csharp"        / "fsharp"
    $nb.metadata.language_info.pygments_lexer   = 'powerShell'         # "csharp"        / "fsharp"
    $nb.metadata.language_info.version          = '7.0'                # "8.0"           / "4.5"
    foreach ($cell in $nb.cells.where({$_.cell_Type -eq    'code' -and
                                       $_.source[0] -match '^#!pwsh'})) {
             $cell.source = $cell.source[1..$cell.source.count]
    }
    if ($FixOutput) {
        foreach ($cell in $nb.cells.where({$_.cell_Type           -eq 'code'    -and
                                           $_.Outputs.output_type -eq 'unknown' -and #all outputtypes are 'unknown'
                                      -not $_.Outputs.output_type -ne 'unknown'})) {
            $h = @{'name'        = 'stdout'
                   'output_type' = 'stream'
                   'text'        =  $cell.outputs.data.'text/plain' -replace '[\r\n]+$',"`n"
            }
            $cell.outputs = ,$h
        }
    }
    if (-not $OutputPath) {$OutputPath = $Path}
    ConvertTo-Json $nb -Depth 10 | Out-File -Encoding utf8 -path $OutputPath
}
