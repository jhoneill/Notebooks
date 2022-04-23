enum size {
    Small
    Medium
    Large
    FamilySize
}
#explicitly allow parameter selection by position (zero-based)
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,Position=0) ]
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


write-host -fo Green "Positional works again"
pizza  FamilySize -extra

write-host -fo Yellow "No standard cheese option"
pizza  FamilySize

