enum size {
    Small
    Medium
    Large
    FamilySize
}
#Use enum, set a default - pipeline accepted although only sets size.
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [size]$Size = 'Medium',

        [switch]$ExtraCheese


    )
    process {
        "Order for a $Size : "
        if ($ExtraCheese) {"With Extra cheese"}

    }
}

write-host -fo Green  "Default-order"
pizza

write-host -fo Green  "Quick-order"
pizza 1

write-host -fo Green "Single-order"
pizza  FamilySize

write-host -fo Green "Multi-order"
"small", "medium" , "large" | Get-Pizza

write-host -fo Green "Add cheese"
pizza FamilySize -ExtraCheese