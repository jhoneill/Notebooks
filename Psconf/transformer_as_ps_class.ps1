using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace System.Drawing.Printing

class PrinterTransformAttribute : ArgumentTransformationAttribute  {
    [object] Transform([EngineIntrinsics]$EngineIntrinsics, [object] $InputData) {
       if ($InputData -in [PrinterSettings]::InstalledPrinters) {
            return $InputData
        }
        else {
          $matchingPrinter = [PrinterSettings]::InstalledPrinters.where({$_ -like "*$inputData*"})
          if (-not $matchingPrinter -or $matchingPrinter.count -gt 1)      {
            Throw [ParameterBindingException]::new("'$InputData' is not a valid printer name.")
          }
          else {return $matchingPrinter}
        }
    }
}

