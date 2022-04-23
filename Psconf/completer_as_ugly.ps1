


function myprint {
param (
    [ArgumentCompleter({
    param(
        [string]      $commandName,
        [string]      $parameterName,
        [string]      $wordToComplete,
        [System.Management.Automation.Language.CommandAst]$commandAst,
        [System.Collections.IDictionary] $fakeBoundParameter
    )

        $wildcard          = ("*" + $wordToComplete + "*")

        [System.Drawing.Printing.PrinterSettings]::InstalledPrinters.where({$_ -like $wildcard }) |
            ForEach-Object –Process {[System.Management.Automation.CompletionResult]::new("'" + $_ + "'")}
    })]
    $name
)
$name
}

