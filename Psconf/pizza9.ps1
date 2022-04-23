enum size {
    Small
    Medium
    Large
    FamilySize
}
# workround
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ParameterSetName="Default",             ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='ExtraCheese',         ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='ExtraCheesePeperoni', ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='ExtraCheeseVegan',    ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='NoCheese',            ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='NoCheesePeperoni',    ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='NoCheeseVegan',       ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='Vegan',               ValueFromPipeline, Position=0)]
        [Parameter(ParameterSetName='Peperoni',            ValueFromPipeline, Position=0)]
        [size]$Size = 'Medium',
        [Parameter(ParameterSetName='ExtraCheese',         ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='ExtraCheesePeperoni', ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='ExtraCheeseVegan',    ValueFromPipelineByPropertyName, Mandatory)]
        [switch]$ExtraCheese,
        [Parameter(ParameterSetName='NoCheese',            ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='NoCheesePeperoni',    ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='NoCheeseVegan',       ValueFromPipelineByPropertyName, Mandatory)]
        [switch]$NoCheese,
        [Parameter(ParameterSetName='Peperoni',            ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='NoCheesePeperoni',    ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='ExtraCheesePeperoni', ValueFromPipelineByPropertyName, Mandatory)]
        [switch]$Peperoni,
        [Parameter(ParameterSetName='Vegan',               ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='NoCheeseVegan',       ValueFromPipelineByPropertyName, Mandatory)]
        [Parameter(ParameterSetName='ExtraCheeseVegan',    ValueFromPipelineByPropertyName, Mandatory)]
        [switch]$Vegan
    )
    process {
    "Order for $size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}


write-host -fo Green "No longer need a cheese parameter"
pizza  FamilySize
