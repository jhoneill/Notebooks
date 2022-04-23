using namespace System.Collections
using namespace System.Drawing.Printing
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

function PrinterNameCompleterFunction {
    param(
        [string]      $commandName,
        [string]      $parameterName,
        [string]      $wordToComplete,
        [CommandAst]  $commandAst,
        [IDictionary] $fakeBoundParameter
    )

        $wildcard          = ("*" + $wordToComplete + "*")

        [PrinterSettings]::InstalledPrinters.where({$_ -like $wildcard }) |
            ForEach-Object –Process {[CompletionResult]::new("'" + $_ + "'")}

}

function myprint1 {
param (

    $name
)
$name
}

Register-ArgumentCompleter -CommandName myprint2 -ParameterName name -ScriptBlock $function:PrinterNameCompleterFunction


function myprint {
param (
    [ArgumentCompleter({PrinterNameCompleterFunction $args})]
    $name
)
$name
}