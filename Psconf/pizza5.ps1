enum size {
    Small
    Medium
    Large
    FamilySize
}
# create a dummy parameter set - size is in *all* sets
function Get-Pizza {
    [cmdletbinding(DefaultParameterSetName="Default")]
    param (
        [Parameter (ValueFromPipeline,Position=0) ]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese')]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese')]
        [switch]$NoCheese
    )
    process {
        "Order for $Size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}

write-host -fo Green "Positional still works "
pizza  FamilySize -extra

write-host -fo Green "And works on its own again "
pizza  FamilySize
