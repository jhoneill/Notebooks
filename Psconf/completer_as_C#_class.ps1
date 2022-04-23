Add-type  -ReferencedAssemblies "System.Drawing", "System.Linq","System.Collections","System.Management.Automation"  @"
using           System.Collections;
using           System.Collections.Generic;
using           System.Drawing.Printing;
using           System.Management.Automation;
using           System.Management.Automation.Language;
using           System.Linq;

public class PrinterNameCompleter : IArgumentCompleter {
     IEnumerable<CompletionResult> IArgumentCompleter.CompleteArgument(
         string        commandName,
         string        parameterName,
         string        wordToComplete,
         CommandAst    commandAst,
         IDictionary   fakeBoundParameters
    )
    {
        WildcardPattern wildcard = new WildcardPattern("*" + wordToComplete + "*", WildcardOptions.IgnoreCase);
        return PrinterSettings.InstalledPrinters.Cast<string>().ToArray().
                    Where(wildcard.IsMatch).Select(s => new CompletionResult("'" + s + "'"));
    }
}
"@ -WarningAction SilentlyContinue


function myprint {

param (
    [ArgumentCompleter([PrinterNameCompleter])]
    $name
)
$name
}
