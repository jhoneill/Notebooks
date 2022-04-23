function V1 {
param ($p)
if ($null -eq $p) {"Version 1 says parameter was empty"}
else              {"Version 1 says it got a parameter"}
}
v1

function V2 {
param ([string]$p)
if ($null -eq $p) {"Version 2 says parameter was empty"}
else              {"Version 2 says it got a parameter"}
}
v2
