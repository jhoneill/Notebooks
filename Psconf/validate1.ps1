
function Validate1 {
param (
    [ValidatePattern("[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}")]
    $id
)
    $id
}
Validate1 1234


function Validate2 {
param (
    [ValidateScript({$_ -match "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}"})]
    $id
)
    $id
}
Validate1 1234


# use a using statement to avoid long names
function Validate3 {
param (
    [ValidateScript({if ($_ -match "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}") {return $true}
                     else {throw [System.Management.Automation.ParameterBindingException]::new("'ID Must be a GUID") }
     })]
    $id
)
    $id
}
Validate3 1234


# The validate pattern attribute gained an error message property in 7 - won't work in Windows PowerShell 5
function Validate1 {
param (
    [ValidatePattern("[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}",ErrorMessage='ID Must be a guid')]
    $id
)
    $id
}

validate1 1234


Function Validate1 {
param (
    [ValidatePattern("[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}",ErrorMessage='ID Must be a guid')]
    $id
)
    $id
}

validator1 1234