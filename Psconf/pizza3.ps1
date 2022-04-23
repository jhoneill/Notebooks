enum size {
    Small
    Medium
    Large
    FamilySize
}
# Parameter sets for cheese options (case sensitive !)
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese')]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese')]
        [switch]$NoCheese
    )
    process {
        "Order for a $Size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}

write-host -fo Yellow "Extra cheese AND No Cheese no longer allowed"
Get-Pizza -extra -no

write-host -fo Green "Single-order"
pizza   -extra

write-host -fo Yellow  "Size could be passed by position -broken now"
pizza  FamilySize

