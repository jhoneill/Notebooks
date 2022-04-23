enum size {
    Small
    Medium
    Large
    FamilySize
}
#as before but being trying to be explicit about the sets
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="Default") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="ExtraCheese") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="NoCheese") ]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese')]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese')]
        [switch]$NoCheese
    )
    process {
    "Order for $size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}


write-host -fo Green "Positional works with a chese parameter "
pizza  FamilySize -extra

write-host -fo Yello "But a cheese parameter is required again "
pizza -Size FamilySize
