enum size {
    Small
    Medium
    Large
    FamilySize
}
#return ability to choose sets based on absence of parameters.
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="Default") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="ExtraCheese") ]
        [Parameter(ValueFromPipeline,Position=0,ParameterSetName="NoCheese") ]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese',Mandatory,ValueFromPipelineByPropertyName)]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese',Mandatory,ValueFromPipelineByPropertyName)]
        [switch]$NoCheese
    )
    process {
    "Order for $size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}


write-host -fo Green "Pipeline works again"
1,2 | Get-Pizza

write-host -fo Yellow "Add some more options"