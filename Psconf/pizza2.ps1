enum size {
    Small
    Medium
    Large
    FamilySize
}
# Cheese options
function Get-Pizza {
    [cmdletbinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [size]$Size = 'Medium',

        [switch]$ExtraCheese,

        [switch]$NoCheese
    )
    process {
        "Order for a $size : "
        if ($ExtraCheese) {"With Extra cheese"}
        if ($NoCheese)    {"Without cheese"}
    }
}

write-host -fo Green "Add cheese"
pizza FamilySize -ExtraCheese

write-host -fo Green "Remove cheese"
pizza FamilySize -no

write-host -fo Green "Extra cheese AND No Cheese ?"
pizza FamilySize  -extra -no
