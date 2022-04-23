
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Drawing.Printing
using namespace System.Management.Automation
using namespace System.Management.Automation.Language


class printerNameCompleterPSClass : IArgumentCompleter {
    [IEnumerable[CompletionResult]] CompleteArgument(
        [string]      $CommandName ,
        [string]      $ParameterName,
        [string]      $WordToComplete,
        [CommandAst]  $CommandAst,
        [IDictionary] $FakeBoundParameters
    )
    {
        $wildcard          = ("*" + $wordToComplete + "*")
        $CompletionResults = [List[CompletionResult]]::new()
        [PrinterSettings]::InstalledPrinters.where({$_ -like $wildcard }) |
            ForEach-Object {$CompletionResults.Add([CompletionResult]::new("'" + $_ + "'"))}
        return $CompletionResults
    }
}

function myprint {

param (
    [ArgumentCompleter([printerNameCompleterPSClass])]
    $name
)
$name
}