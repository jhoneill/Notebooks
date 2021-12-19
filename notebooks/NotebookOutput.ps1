Function Out-Cell{
    <#
        .synopsis
            Outputs a notebook cell - takes a script block, or html or objects to format as a list/table
        .description
            This command has three ways of working. It can
            * Take HTML (via the pipeline or as a parameter) and output it into a cell
            * Make an HTML table or list from objects, selecting properties, first, last etc.
            * Take a script block to generate html or objects to transform to a list/table
        .example
        > Get-command -Module  Microsoft.DotNet.Interactive.PowerShell | Out-Cell -AsTable name,version

        Takes CommandInfo objects and displays their name and version as an HTML Table
        .example
        > Cell -AsList name,version { Get-command -Module  Microsoft.DotNet.Interactive.PowerShell }

        Similar to the previous object this uses the alias "cell" and uses a script block to create
        the objects and formats their name and version as an HTML List
        .example
        > cell  {plot_pipeline FollowOn.pipeline.yml  -DestinationPath "" }

        In this example, `plot_pipeline` reads a yml file and draws a simple SVG graph.
}
    #>
    [cmdletbinding(DefaultParameterSetName="Default")]
    [alias("cell")]
    param   (
        [Parameter(ParameterSetName='Default', Mandatory=$true, Position=0, ValueFromPipeline=$true )]
        [Parameter(ParameterSetName='List',    Mandatory=$true, Position=1, ValueFromPipeline=$true )]
        [Parameter(ParameterSetName='Table',   Mandatory=$true, Position=1, ValueFromPipeline=$true )]
        [Parameter(ParameterSetName='Text',    Mandatory=$true, Position=1, ValueFromPipeline=$true )]
        $InputObject,

        [Parameter(ParameterSetName='List',    Mandatory=$true)]
        [Alias('List')]
        [switch]$AsList,

        [Parameter(ParameterSetName='Table',   Mandatory=$true)]
        [Alias('Table')]
        [switch]$AsTable,

        [Parameter(ParameterSetName='Text',    Mandatory=$true)]
        [Alias('Text')]
        [switch]$AsText,

        [Parameter(ParameterSetName='Table',Position=0)]
        [Parameter(ParameterSetName='List' ,Position=0)]
        $Property,

        [Parameter(ParameterSetName='Table')]
        [Parameter(ParameterSetName='List')]
        [string[]]$ExcludeProperty,

        [Parameter(ParameterSetName='Table')]
        [Parameter(ParameterSetName='List')]
        [int32]$First,

        [Parameter(ParameterSetName='Table')]
        [Parameter(ParameterSetName='List')]
        [int32]$Last,

        [Parameter(ParameterSetName='Table')]
        [Parameter(ParameterSetName='List')]
        [int32]$Skip,

        [switch]$PassThru
    )
    begin   {
            $data = @()
    }
    process {
        if ($InputObject -is [scriptblock]) {
                $data += Invoke-Command -ScriptBlock $InputObject
        }
        else {  $data += $InputObject }
    }
    end     {
        if     ($AsText) {
            $t = $data | Out-String
            $d = [Microsoft.DotNet.Interactive.Kernel]::display($t.Trim(),"text/plain")
            if ($passThru) {return $d} else {return}
        }
        elseif (-not ($AsTable -or $AsList)) {
            $html = $data -join ""
        }
        else {
            $selectParameterNames = @("First","Last","Skip","Property","ExcludeProperty")
            if ($PSBoundParameters[$selectParameterNames]) {
                $selectParams = @{}
                foreach ($p in $selectParameterNames.Where({$PSBoundParameters.ContainsKey($_)})) {
                    $selectParams[$p]=$PSBoundParameters[$p]
                }
                $data = $data | Select-Object @selectParams
            }

            if ($AsList) {$html = $data | ConvertTo-Html -Fragment -As "List"}
            else         {$html = $data | ConvertTo-Html -Fragment -As "Table"}
        }
        [Microsoft.DotNet.Interactive.Kernel]::HTML($html) | Out-Display -passthru:$PassThru
    }
}
function Write-Progress {
    param (
        [Parameter(Mandatory=$true,position = 0)]
        [string]$Activity,
        [Parameter(position = 1)]
        [string]$Status,
        [string]$CurrentOperation,
        [int]$PercentComplete,
        [int]$SecondsRemaining,
        [switch]$Completed
    )
    if ($status)            {$bar = "{0,-100}"  -f $Status}
    else                    {$bar = "{0,-100}"  -f $CurrentOperation} #even if it is empty!
    if ($PercentComplete)   {$bar = $PSStyle.Background.blue + $PSStyle.Foreground.BrightWhite +
                                    ($bar -replace "(?<=^.{$percentComplete})", ($PSStyle.Reset + $PSStyle.Foreground.blue))
    }
    if ($SecondsRemaining) {$bar +=  $SecondsRemaining.tostring("0s") }
    if ($Completed)        {$bar = ' '}
    else                   {$bar = $PSStyle.Foreground.blue + $Activity +  "[" + $bar + "]" + $PSStyle.Reset}

    if ($global:ProgressBar -and $global:contextID -eq  [Microsoft.DotNet.Interactive.KernelInvocationContext]::Current.Command.Properties.id) {
        $global:ProgressBar.Update($bar)
    }
    else {
        $global:ProgressBar = $bar | Out-Display -PassThru -MimeType text/plain
        $global:contextID   =  [Microsoft.DotNet.Interactive.KernelInvocationContext]::Current.Command.Properties.id
    }
}

function Out-Mermaid {
    [alias('Mermaid')]
    param (
        [parameter(ValueFromPipeline=$true,Mandatory=$true,Position=0)]
        $Text
    )
    begin {
        $mermaid = ""
        $guid    = ([guid]::NewGuid().ToString() -replace '\W','')
        $html    = @"
<div style="background-color:white;"><script type="text/javascript">
loadMermaid_$guid = () => {(require.config({ 'paths': { 'context': '1.0.252001', 'mermaidUri' : 'https://colombod.github.io/dotnet-interactive-cdn/extensionlab/1.0.252001/mermaid/mermaidapi', 'urlArgs': 'cacheBuster=7de2aec4927849b5a989d2305cf957bc' }}) || require)(['mermaidUri'], (mermaid) => {let renderTarget = document.getElementById('$guid'); mermaid.render( 'mermaid_$guid', ``~~Mermaid~~``, g => {renderTarget.innerHTML = g  });}, (error) => {console.log(error);});}
if ((typeof(require) !==  typeof(Function)) || (typeof(require.config) !== typeof(Function))) {
    let require_script = document.createElement('script');
    require_script.setAttribute('src', 'https://cdnjs.cloudflare.com/ajax/libs/require.js/2.3.6/require.min.js');
    require_script.setAttribute('type', 'text/javascript');
    require_script.onload = function() {loadMermaid_$guid();};
    document.getElementsByTagName('head')[0].appendChild(require_script);
}
else {loadMermaid_$guid();}
</script><div id="$guid"></div></div>
"@  }
    process {$Mermaid +=  ("`r`n" + $Text -replace '^[\r\n]+','' -replace '[\r\n]+$','') }
    end     {[Microsoft.DotNet.Interactive.Kernel]::HTML(($html -replace  '~~Mermaid~~',$mermaid ))  | Out-Display }
}