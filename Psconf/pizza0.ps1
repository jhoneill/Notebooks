






function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter (ValueFromPipeline,Mandatory) ] [ValidateSet( "Small","Large","FamilySize" ) ]
        [string]$Size
        )
    process {
    "Order for $size : "
    }
}



write-host -fo Green "Single-order"
pizza  FamilySize

write-host -fo Green "Multi-order"
"small", "small" , "large" | Get-Pizza

<#
 "Quick-order"  doesn't work
pizza
#>