enum size {
    Small
    Medium
    Large
    FamilySize
}
#make it clear how to decide we're in a cheese set
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="Default") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="ExtraCheese") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="NoCheese") ]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese',Mandatory)]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese',Mandatory)]
        [switch]$NoCheese
    )
    process {
    "Order for $size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}

write-host -fo Green "No longer need a cheese parameter"
pizza  FamilySize


write-host -fo Yellow "But we broke the pipeline"
1,2 | Get-Pizza
