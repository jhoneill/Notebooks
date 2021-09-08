$Script:PSModuleRoot = $PSScriptRoot
# Importing from [C:\Users\mcp\Documents\GitHub\PSGraph\PSGraph\Private]
# .\PSGraph\Private\ConvertTo-GraphVizAttribute.ps1
function ConvertTo-GraphVizAttribute
{
    <#
        .Description
        Converts a hashtable to a key value pair format that the DOT specification uses for nodes, edges and graphs

        .Example
            ConvertTo-GraphVizAttribute @{label='myName'}

            [label="myName";]

             For edge and nodes, it like this [key1="value";key2="value"]

        .Example
            ConvertTo-GraphVizAttribute @{label='myName';color='Red'} -UseGraphStyle

                label="myName";
                color="Red";

            For graphs, it needs to be indented and multiline
            key1="value";
            key2="value";

        .Example
            ConvertTo-GraphVizAttribute @{label={$_.name}} -InputObject @{name='myName'}

            [label="myName";]

            Script blocks are supported in the hashtable for some commands.
            InputObject is the $_ value in the scriptblock

        .Notes
        For edge and nodes, it like this [key1="value";key2="value"]
        For graphs, it needs to be indented and multiline
            key1="value";
            key2="value";

        Script blocks are supported in the hashtable for some commands.
        InputObject is the $_ value in the scriptblock
    #>
    param(
        [hashtable]
        $Attributes = @{},

        [switch]
        $UseGraphStyle,

        # used for whe the attributes have scriptblocks embeded
        [object]
        $InputObject,

        # source node for cluster edge detection
        [string]
        $From,

        # target node for cluster edge detection
        [string]
        $To
    )

    if ($null -eq $script:SubGraphList)
    {
        $script:SubGraphList = @{}
    }
    if ( $From -and $script:SubGraphList.contains($From) )
    {
        $Attributes.ltail = $script:SubGraphList[$From]
    }
    if ( $To -and $script:SubGraphList.contains($To) )
    {
        $Attributes.lhead = $script:SubGraphList[$To]
    }

    if ($Attributes -ne $null -and $Attributes.Keys.Count -gt 0)
    {
        $values = foreach ( $key in $Attributes.GetEnumerator() )
        {
            if ($key.value -is [scriptblock])
            {
                Write-Debug "Executing Script on Key $($key.name)"
                $value = ( [string]( @( $InputObject ).ForEach( $key.value ) ) )
            }
            else
            {
                $value = $key.value
            }
            '{0}={1};' -f ( Format-KeyName $key.name ), ( Format-Value $value )
        }

        if ( $UseGraphStyle )
        {
            # Graph style is each line on its own and no brackets
            $indent = Get-Indent
            $values | ForEach-Object {"$indent$_"}
        }
        else
        {
            "[{0}]" -f ( $values -join '' )
        }

    }
}

# .\PSGraph\Private\Format-KeyName.ps1
function Format-KeyName
{
    [OutputType('System.String')]
    [cmdletbinding()]
    param(
        [Parameter(Position = 0)]
        [string]
        $InputObject
    )
    begin
    {
        $translate = @{
            Damping = 'Damping'
            K       = 'K'
            URL     = 'URL'
        }
    }
    process
    {
        $InputObject = $InputObject.ToLower()
        if ( $translate.ContainsKey( $InputObject ) )
        {
            return $translate[ $InputObject ]
        }
        return $InputObject
    }
}
# .\PSGraph\Private\Format-Value.ps1
function Format-Value
{
    param(
        $value,

        [switch]
        $Edge,

        [switch]
        $Node
    )

    begin
    {
        if ( $null -eq $Script:CustomFormat )
        {
            Set-NodeFormatScript
        }
    }
    process
    {
        # edges can point to record cells
        if ($Edge -and
            # is not surounded by explicit quotes
            $value -notmatch '^".*"$' -and
            # has record notation with a word as a target
            $value -match '^(?<node>.+):(?<Record>(\w+))$'
        )
        {
            # Recursive call to this function to format just the node
            "{0}:{1}" -f (Format-Value $matches.node -Node), $matches.record
        }
        else
        {
            # Allows for custom node ID formats
            if ( $Edge -Or $Node )
            {
                $value = @($value).ForEach($Script:CustomFormat)
            }

            switch -Regex ( $value )
            {
                # HTML label, special designation
                '^<\s*table.*>.*'
                {
                    "<$PSItem>"
                }
                '^".*"$'
                {
                    [string]$PSItem
                }
                # Anything else, use quotes
                default
                {
                    '"{0}"' -f ( [string]$PSItem ).Replace("`"", '\"') # Escape quotes in the string value
                }
            }
        }
    }
}

# .\PSGraph\Private\Get-ArgumentLookUpTable.ps1
Function Get-ArgumentLookupTable
{
    return @{
        # OutputFormat
        Version         = 'V'
        Debug           = 'v'
        GraphName       = 'Gname={0}'
        NodeName        = 'Nname={0}'
        EdgeName        = 'Ename={0}'
        OutputFormat    = 'T{0}'
        LayoutEngine    = 'K{0}'
        ExternalLibrary = 'l{0}'
        DestinationPath = 'o{0}'
        AutoName        = 'O'
    }
}

# .\PSGraph\Private\Get-GraphVizArgument.ps1
function Get-GraphVizArgument
{
    <#
        .Description
        Takes an array and converts it to commandline arguments for GraphViz

        .Example
        Get-GraphVizArgument -InputObject @{OutputFormat='jpg'}

        .Notes
        If no destination is provided, it will set the auto name flag.
        If there is no output format, it guesses from the destination
    #>

    [cmdletbinding()]
    param(
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [hashtable]
        $InputObject = @{}
    )

    process
    {
        if ( $InputObject -ne $null )
        {
            $InputObject = Update-DefaultArgument -InputObject $InputObject
            $arguments = Get-TranslatedArgument -InputObject $InputObject
        }

        return $arguments
    }
}

# .\PSGraph\Private\Get-Indent.ps1
function Get-Indent
{
    [cmdletbinding()]
    param( $depth = $script:indent )
    process
    {
        if ( $null -eq $depth -or $depth -lt 0 )
        {
            $depth = 0
        }
        Write-Debug "Depth $depth"
        (" " * 4 * $depth )
    }
}

# .\PSGraph\Private\Get-LayoutEngine.ps1
function Get-LayoutEngine( $name )
{
    $layoutEngine = @{
        Hierarchical      = 'dot'
        SpringModelSmall  = 'neato'
        SpringModelMedium = 'fdp'
        SpringModelLarge  = 'sfdp'
        Radial            = 'twopi'
        Circular          = 'circo'
        dot               = 'dot'
        neato             = 'neato'
        fdp               = 'fdp'
        sfdp              = 'sfdp'
        twopi             = 'twopi'
        circo             = 'circo'
    }

    return $layoutEngine[$name]
}

# .\PSGraph\Private\Get-OutputFormatFromPath.ps1
function Get-OutputFormatFromPath( [string]$path )
{
    $formats = @(
        'jpg'
        'png'
        'gif'
        'imap'
        'cmapx'
        'jp2'
        'json'
        'pdf'
        'plain'
        'dot'
    )

    foreach ( $ext in $formats )
    {
        if ( $Path -like "*.$ext" )
        {
            return $ext
        }
    }
}

# .\PSGraph\Private\Get-TranslatedArgument.ps1
function Get-TranslatedArgument( $InputObject )
{
    $paramLookup = Get-ArgumentLookUpTable

    Write-Verbose 'Walking parameter mapping'
    foreach ( $key in $InputObject.keys )
    {
        Write-Debug $key
        #A hashtable key can't be null. Don't pass null or empty string. (But allow zero, false etc.) 
        #This means we can get output to std-out by making the destination an empty string.
        if ( -not [string]::IsNullOrEmpty($InputObject[$key]) -and $paramLookup.ContainsKey( $key ) )
        {
            $newArgument = $paramLookup[$key]
            if ( $newArgument -like '*{0}*' )
            {
                $newArgument = $newArgument -f $InputObject[$key]
            }

            Write-Debug $newArgument
            "-$newArgument"
        }
    }
}

# .\PSGraph\Private\Update-DefaultArgument.ps1
function Update-DefaultArgument
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSUseShouldProcessForStateChangingFunctions", "" )]
    [cmdletbinding()]
    param ( $inputObject )

    if ( $InputObject.ContainsKey( 'LayoutEngine' ) )
    {
        Write-Verbose 'Looking up and replacing rendering engine string'
        $InputObject['LayoutEngine'] = Get-LayoutEngine -Name $InputObject['LayoutEngine']
    }

    if ( -Not $InputObject.ContainsKey( 'DestinationPath' ) )
    {
        $InputObject["AutoName"] = $true;
    }

    if ( -Not $InputObject.ContainsKey( 'OutputFormat' ) )
    {
        Write-Verbose "Tryig to set OutputFormat to match file extension"
        $outputFormat = Get-OutputFormatFromPath -Path $InputObject['DestinationPath']
        if ( $outputFormat )
        {
            $InputObject["OutputFormat"] = $outputFormat
        }
        else
        {
            $InputObject["OutputFormat"] = 'png'
        }
    }

    return $InputObject
}

# Importing from [C:\Users\mcp\Documents\GitHub\PSGraph\PSGraph\Public]
# .\PSGraph\Public\Cells.ps1
function Cells
{
    [OutputType('System.String')]
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        $InputObject,

        $Properties = '*' ,
        [string[]]
        $ExcludeProperty,
        [ValidateSet('LEFT','CENTER','RIGHT')]
        $Align = "LEFT",
        [string]
        $PortPoroperty,
        [switch]
        $HtmlEncode,
        [switch]
        $NoHeader
    )
    begin {
        $portlist = @{}
        $script:Header = @()
    }
    process
    {
        foreach ($Targetdata in $InputObject) {
            if (-not $script:Header) {
                foreach ($p in $Properties) {
                    $InputObject.PSObject.Properties.where({$_.name -like $p}).Name | ForEach-Object {
                        if ($_ -notin $script:Header) {$script:Header += $_ }
                    }
                }
                foreach ($exclusion in $ExcludeProperty) {$script:Header = $script:Header -notlike $exclusion}
                if (-not $NoHeader) {
                    $row =  "<tr>"
                    foreach ($Name in $script:Header) {
                        $row += ('<TD ALIGN="{1}"><B>{0}</B></TD>' -f $Name, $Align.toupper())
                    }
                    $row + "</tr>"
                }
            }
            $row =  "<tr>"
            foreach ($Name in $script:Header) {
                $cellText = ($TargetData.$Name).tostring()
                $newPortName = $cellText -replace '\W',''

                if ( $PortPoroperty -eq $name -and -not $portlist[$newPortName])
                {
                    $row += ('<TD PORT="{1}" ALIGN="{0}">' -f  $Align.toupper(), $newPortName)
                    $portlist[$newPortName] = $true
                }
                else
                {
                    $row += ('<TD ALIGN="{0}">' -f  $Align.toupper())
                }
                if ($HtmlEncode)
                {
                    $row +=  ([System.Net.WebUtility]::HtmlEncode($cellText)) + '</TD>'
                }
                else {
                    $row += $cellText + '</TD>'
                }
            }
            $row + "</tr>"
        }
    }
}
# .\PSGraph\Public\Edge.ps1
function Edge
{
    <#
        .Description
        This defines an edge between two or more nodes

        .Example
        Graph g {
            Edge FirstNode SecondNode
        }

        Generates this graph syntax:

        digraph g {
            "FirstNode"->"SecondNode"
        }

        .Example
        $folder = Get-ChildItem -Recurse -Directory
        graph g {
            $folder | %{ edge $_.parent $_.name }
        }

        # with parameter names specified
        graph g {
            $folder | %{ edge -From $_.parent -To $_.name }
        }

        # with scripted properties
        graph g {
            edge $folder -FromScript {$_.parent} -ToScript {$_.name}
        }

        .Example
        $folder = Get-ChildItem -Recurse -Directory


        .Example
        graph g {
            edge (1..3) (5..7)
            edge top bottom @{label="line label"}
            edge (10..13)
            edge one,two,three,four
        }

        .Notes
        If an array is specified for the From property, but not for the To property, then the From list will be procesed in order and will map the array in a chain.

    #>
    [cmdletbinding( DefaultParameterSetName = 'Node' )]
    param(
        # start node or source of edge
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Node',
            ValueFromPipelineByPropertyName = $true
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Attributes'
        )]
        [alias( 'NodeName', 'Name', 'SourceName', 'LeftHandSide', 'lhs' )]
        [string[]]
        $From,

        # Destination node or target of edge
        [Parameter(
            Mandatory = $false,
            Position = 1,
            ParameterSetName = 'Node',
            ValueFromPipelineByPropertyName = $true
        )]
        [alias('Destination', 'TargetName', 'RightHandSide', 'rhs')]
        [string[]]
        $To,

        # Hashtable that gets translated to an edge modifier
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Attributes'
        )]
        [Parameter(
            Position = 2,
            ParameterSetName = 'Node'
        )]
        [Parameter(
            Position = 1,
            ParameterSetName = 'script'
        )]
        [hashtable]
        $Attributes = @{},

        # a list of nodes to process
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ParameterSetName = 'script'
        )]
        [Alias('InputObject')]
        [Object[]]
        $Node,

        # start node script or source of edge
        [Parameter(ParameterSetName = 'script')]
        [alias('FromScriptBlock', 'SourceScript')]
        [scriptblock]
        $FromScript = {$_},

        # Destination node script or target of edge
        [Parameter(ParameterSetName = 'script')]
        [alias('ToScriptBlock', 'TargetScript')]
        [scriptblock]
        $ToScript = {$null},

        # A string for using native attribute syntax
        [string]
        $LiteralAttribute = $null,

        #Label for the edge, escaped or HTML Text
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [AllowEmptyString()]
        [String]
        $Label,

        #Style for the edge, dashed, solid etc.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("dashed", "dotted", "solid", "invis", "bold" , "tapered")]
        [String]
        $Style,

        #Indicates which ends of the edge should be decorated with an arrowhead.
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('forward','back','both','none')]
        [String]
        $Direction,

        # Not used, but can be specified for verbosity
        [switch]
        $Default
    )

    begin
    {
        #re-create any scriptblock passed as a parameter, otherwise variables in this function are out of its scope.
        if ($ToScript)
        {
            $ToScript   = [scriptblock]::create( $ToScript )
        }
        if ($FromScript)
        {
            $FromScript = [scriptblock]::create( $FromScript )
        }
        #moved handling of $LiteralAttribute to make behavior later easier to follow
    }

    process
    {
        try
        {
            #Don't want to make all possible attributes parameters, just key ones, label , direction and style for the edge
            if ($PSBoundParameters.ContainsKey('Label')) #Label may be an empty string.
            {
                $Attributes['label'] = $Label
            }
            if ($Style) #Style must not be empty but wrong case may slip though
            {
                $Attributes['style'] = $Style.ToLower()
            }
            if ($Direction) #Same agaign
            {
                $Attributes['dir'] = $Direction.ToLower()
            }
            if ( $Node.count -eq 1 -and $node[0] -is [Hashtable] -and !$PSBoundParameters.ContainsKey('FromScript') -and !$PSBoundParameters.ContainsKey('ToScript') )
            {
                #Deducing the pattern 'edge @{}' as default edge definition
                $GraphVizAttribute = ConvertTo-GraphVizAttribute -Attributes $Node[0]
                '{0}edge {1}' -f (Get-Indent), $GraphVizAttribute
            }
            elseif ( $null -ne $Node )
            {
                # Used when scripted properties are specified
                foreach ( $item in $Node )
                {
                    $fromValue = ( @($item).ForEach($FromScript) )
                    $toValue = ( @($item).ForEach($ToScript) )

                    $LiteralAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes -InputObject $item -From $fromValue -To $toValue

                    edge -From $fromValue -To $toValue -LiteralAttribute $LiteralAttribute
                }
            }
            else
            {
                if ( $null -ne $To )
                {
                    # If we have a target array, cross multiply results
                    foreach ( $sNode in $From )
                    {
                        foreach ( $tNode in $To )
                        {
                            if ( $LiteralAttribute)
                            {
                                  $GraphVizAttribute = $LiteralAttribute
                            }
                            else
                            {
                                  $GraphVizAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes -From $sNode -To $tNode
                            }
                            if  ( $GraphVizAttribute -match 'ltail=' -or $GraphVizAttribute -match 'lhead=')
                            {
                                # our subgraph to subgraph edges can crash the layout engine
                                # adding invisible edge for layout hints helps resolve this
                                Edge -From $sNode -To $tNode -LiteralAttribute '[style=invis]'
                            }

                            '{0}{1}->{2} {3}' -f (Get-Indent),
                                (Format-Value $sNode -Edge),
                                (Format-Value $tNode -Edge),
                                $GraphVizAttribute
                        }
                    }
                }
                else
                {
                    # If we have a single array, connect them sequentially.
                    for ( $index = 0; $index -lt ( $From.Count - 1 ); $index++ )
                    {
                        if ([string]::IsNullOrEmpty( $LiteralAttribute ) )
                        {
                            $GraphVizAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes -From $From[$index] -To $From[$index + 1]
                        }
                        ('{0}{1}->{2} {3}' -f (Get-Indent),
                            (Format-Value $From[$index] -Edge),
                            (Format-Value $From[$index + 1] -Edge),
                            $GraphVizAttribute
                        )
                    }
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\Entity.ps1

Enum EntityType
{
    Name
    Value
    TypeName
}

Function Entity
{
    <#
    .SYNOPSIS
    Convert an object into a PSGraph Record

    .DESCRIPTION
    Convert an object into a PSGraph Record

    .PARAMETER InputObject
    The object to convert into a record

    .PARAMETER Name
    The name of the node

    .PARAMETER Show
    The different details to show in the record.

    Name : The property name
    Value : The property name and value
    TypeName : The property name and the value type

    .PARAMETER Property
    The list of properties to display. Default is to list them all.
    Supports wildcards.

    .EXAMPLE

    $sample = [pscustomobject]@{
        first = 1
        second = 'two'
    }
    graph {
        $sample |  Entity -Show TypeName
    } | export-PSGraph -ShowGraph

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [parameter(
            ValueFromPipeline,
            position = 0
        )]
        $InputObject,

        [string]
        $Name,

        [string[]]
        $Property,

        [EntityType]
        $Show = [EntityType]::TypeName
    )

    end
    {
        if ([string]::isnullorempty($Name) )
        {
            $Name = $InputObject.GetType().Name
        }

        if ($InputObject -is [System.Collections.IDictionary])
        {
            $members = $InputObject.keys
        }
        else
        {
            $Members = $InputObject.PSObject.Properties.Name
        }

        $rows = foreach ($propertyName in $members)
        {
            if ($null -ne $Property)
            {
                $matches = $property | Where-Object {$propertyName -like $_}
                if ($null -eq $matches)
                {
                    continue
                }
            }

            $value = $inputobject.($propertyName)
            switch ($Show)
            {
                Name
                {
                    Row "<B>$propertyName</B>" -Name $propertyName
                }
                TypeName
                {
                    if ($null -ne $value)
                    {
                        $type = $value.GetType().Name
                    }
                    else
                    {
                        $type = 'null'
                    }
                    Row ('<B>{0}</B> <I>[{1}]</I>' -f $propertyName, $type) -Name $propertyName
                }
                Value
                {
                    if ([string]::IsNullOrEmpty($value))
                    {
                        $value = ' '
                    }
                    elseif ($value.count -gt 1)
                    {
                        $value = '[object[]]'
                    }
                    Row ('<B>{0}</B> : <I>{1}</I>' -f $propertyName, ([System.Net.WebUtility]::HtmlEncode($value))) -Name $propertyName
                }
            }
        }

        Record -Name $Name -Row $rows
    }
}

# .\PSGraph\Public\Export-PSGraph.ps1
function Export-PSGraph
{
    <#
        .Description
        Invokes the graphviz binaries to generate a graph.
        .PARAMETER Source
        The GraphViz file to process or contents of the graph in Dot notation
        .PARAMETER DestinationPath
        The destination for the generated file.
        .PARAMETER OutputFormat
        The file type used when generating an image
        .PARAMETER LayoutEngine
        The layout engine used to generate the image
        .PARAMETER GraphVizPath
        Path or paths to the dot graphviz executable. Some sensible defaults are used if nothing is passed.
        .PARAMETER ShowGraph
        Launches the graph when done
        .Example
        Export-PSGraph -Source graph.dot -OutputFormat png

        .Example
        graph g {
            edge (3..6)
            edge (5..2)
        } | Export-PSGraph -Destination $env:temp\test.png

        .Notes
        The source can either be files or piped graph data.

        It checks the piped data for file paths. If it cannot find a file, it assumes it is graph data.
        This may give unexpected errors when the file does not exist.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    [cmdletbinding()]
    param(
        # The GraphViz file to process or contents of the graph in Dot notation
        [Parameter(
            ValueFromPipeline = $true
        )]
        [Alias('InputObject', 'Graph', 'SourcePath')]
        [string[]]
        $Source,

        #The destination for the generated file.
        [Parameter(
            Position = 0
        )]
        [string]
        $DestinationPath,

        # The file type used when generating an image
        [ValidateSet('jpg', 'png', 'gif', 'imap', 'cmapx', 'jp2', 'json', 'pdf', 'plain', 'dot', 'svg')]
        [string]
        $OutputFormat = 'png',

        # The layout engine used to generate the image
        [ValidateSet(
            'Hierarchical',
            'SpringModelSmall' ,
            'SpringModelMedium',
            'SpringModelLarge',
            'Radial',
            'Circular',
            'dot',
            'neato',
            'fdp',
            'sfdp',
            'twopi',
            'circo'
        )]
        [string]
        $LayoutEngine,

        [Parameter()]
        [string[]]
        $GraphVizPath = (
            'C:\Program Files\NuGet\Packages\Graphviz*\dot.exe',
            'C:\program files*\GraphViz*\bin\dot.exe',
            '/usr/local/bin/dot',
            '/usr/bin/dot'
        ),

        # launches the graph when done
        [switch]
        $ShowGraph
    )

    begin
    {
        try
        {
            # Use Resolve-Path to test all passed paths
            # Select only items with 'dot' BaseName and use first one
            $graphViz = Resolve-Path -path $GraphVizPath -ErrorAction SilentlyContinue | Get-Item | Where-Object BaseName -eq 'dot' | Select-Object -First 1

            if ( $null -eq $graphViz )
            {
                $GraphvizPathString = $GraphVizPath -Join " or "
                throw "Could not find GraphViz installed on this system. Please run 'Install-GraphViz' to install the needed binaries and libraries. This module just a wrapper around GraphViz and is looking for it in the following paths: $($GraphvizPathString). Optionally pass a path to your dot.exe file with the GraphVizPath parameter"
            }

            $useStandardInput = $false
            $standardInput = New-Object System.Text.StringBuilder
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    process
    {
        try
        {
            if ( $null -ne $Source -and $Source.Count -gt 0 )
            {
                # if $Source is a list of files, process each one
                $fileList = $null

                # Only resolve paths, if there are NO empty string entries in the $Source
                # Resolve-path spits out an error with empty string paths, even with SilentlyContinue
                if ( @( $Source | Where-Object { [String]::IsNullOrEmpty($_) } ).Count -eq 0 )
                {
                    try
                    {
                        $fileList = Resolve-Path -Path $Source -ErrorAction Stop
                    }
                    catch
                    {
                        # I don't care that it isn't a file, I'll do something else with the data
                        $fileList = $null
                    }
                }

                if ( $null -ne $fileList -and $Source.Count -gt 0 )
                {
                    foreach ( $file in $fileList )
                    {
                        Write-Verbose "Generating graph from '$($file.path)'"
                        $arguments = Get-GraphVizArgument -InputObject $PSBoundParameters
                        $null = & $graphViz @($arguments + $file.path)
                        if ($LastExitCode)
                        {
                            Write-Error -ErrorAction Stop -Exception ([System.Management.Automation.ParseException]::New())
                        }
                    }
                }
                else
                {
                    Write-Debug 'Using standard input to process graph'
                    $useStandardInput = $true
                    [void]$standardInput.AppendLine($Source)
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }

    end
    {
        try
        {

            if ( $useStandardInput )
            {
                Write-Verbose 'Processing standard input'
                #Create a destination path if there is none, but if it is an empty string don't resolve it
                #This allows empty string to mean "send graphviz output to stdOut"    
                if ( -Not $PSBoundParameters.ContainsKey( 'DestinationPath' ) )
                {
                    Write-Verbose '  Creating temporary path to save graph'

                    if ( $standardInput[0] -match 'graph\s+(?<filename>.+)\s+{' )
                    {
                        $file = $Matches.filename
                    }
                    else
                    {
                        $file = [System.IO.Path]::GetRandomFileName()
                    }
                    $PSBoundParameters["DestinationPath"] = Join-Path ([system.io.path]::GetTempPath()) "$file.$OutputFormat"
                }
                elseif (-not [string]::IsNullOrEmpty($PSBoundParameters["DestinationPath"]) )
                {
                    $PSBoundParameters["DestinationPath"] =  $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath)
                }
                $arguments = Get-GraphVizArgument $PSBoundParameters
                Write-Verbose " Arguments: $($arguments -join ' ')"

                $result =  $standardInput.ToString() | & $graphViz @($arguments)
                if ($LastExitCode)
                {
                    Write-Error -ErrorAction Stop -Exception ([System.Management.Automation.ParseException]::New())
                }
                elseif ( [string]::IsNullOrEmpty($PSBoundParameters["DestinationPath"])) 
                {
                    return $result
                }

                if ( $ShowGraph )
                {
                    # Launches image with default viewer as decided by explorer
                    Write-Verbose "Launching $($PSBoundParameters["DestinationPath"])"
                    Invoke-Expression $PSBoundParameters["DestinationPath"]
                }

                Get-ChildItem $PSBoundParameters["DestinationPath"]
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
}

# .\PSGraph\Public\Graph.ps1
function Graph
{
    <#
        .Description
        Defines a graph. The base collection that holds all other graph elements

        .Example
        graph g {
            node top,left,right @{shape='rectangle'}
            rank left,right
            edge top left,right
        }

        .Example

        $dot = graph {
            edge hello world
        }

        .Notes
        The output is a string so it can be saved to a variable or piped to other commands
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidDefaultValueForMandatoryParameter", "" )]
    [CmdletBinding( DefaultParameterSetName = 'Default' )]
    [Alias( 'DiGraph' )]
    [OutputType( [string] )]
    param(

        # Name or ID of the graph
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Named'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'NamedAttributes'
        )]
        [string]
        $Name = 'g',

        # The commands to execute inside the graph
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Default'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Named'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Attributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 2,
            ParameterSetName = 'NamedAttributes'
        )]
        [scriptblock]
        $ScriptBlock,

        # Hashtable that gets translated to graph attributes
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'NamedAttributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Attributes'
        )]
        [hashtable]
        $Attributes = @{},

        # Keyword that initiates the graph
        [string]
        $Type = 'digraph'
    )

    begin
    {
        try
        {
            Write-Verbose "Begin Graph $type $Name"
            if ($Type -eq 'digraph')
            {
                $script:indent = 0
                $Attributes.compound = 'true'
                $script:SubGraphList = @{}
            }

            "{0}{1} {2} {{" -f (Get-Indent), $Type, $name
            $script:indent++

            if ($Attributes -ne $null)
            {
                ConvertTo-GraphVizAttribute -Attributes $Attributes -UseGraphStyle
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    process
    {
        try
        {
            Write-Verbose "Process Graph $type $name"

            if ( $type -eq 'subgraph' )
            {
                $nodeName = $name.Replace('cluster', '')
                $script:SubGraphList[$nodeName] = $name
                Node $nodeName @{ shape = 'point'; style = 'invis'; label = '' }
            }

            & $ScriptBlock
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    end
    {
        try
        {
            $script:indent--
            if ( $script:indent -lt 0 )
            {
                $script:indent = 0
            }
            "$(Get-Indent)}" # Close braces
            "" #Blank line
            Write-Verbose "End Graph $type $name"
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\Inline.ps1
function Inline
{
    <#
        .Description
        Allows you to write native DOT format commands inline with proper indention

        .Example
        graph g {
            inline 'node [shape="rect";]'
        }
        .Notes
        You can just place a string in the graph, but it will not indent correctly. So all this does is give you correct indents.
    #>
    [cmdletbinding()]
    param(
        # The text to generate inline with the graph
        [string[]]
        $InlineCommand
    )

    process
    {
        try
        {
            foreach ($line in $InlineCommand)
            {
                "{0}{1}" -f (Get-Indent), $line
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }

    }
}

# .\PSGraph\Public\Install-GraphViz.ps1
function Install-GraphViz
{
    <#
        .Description
        Installs GraphViz package using online provider
        .Example
        Install-GraphViz
    #>
    [cmdletbinding( SupportsShouldProcess = $true, ConfirmImpact = "High" )]
    param()

    process
    {
        try
        {
            if ( $IsOSX )
            {
                if ( $PSCmdlet.ShouldProcess( 'Install graphviz' ) )
                {
                    brew install graphviz
                }
            }
            else
            {
                if ( $PSCmdlet.ShouldProcess('Register Chocolatey provider and install graphviz' ) )
                {
                    if ( -Not ( Get-PackageProvider | Where-Object ProviderName -eq 'Chocolatey' ) )
                    {
                        Register-PackageSource -Name Chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/
                    }

                    Find-Package graphviz | Install-Package -Verbose -ForceBootstrap
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\New-EdgeAttributeSet.ps1
Function New-EdgeAttributeSet {
    <#
      .synopsis
        Creates a set of attributes for the node command.
      .description
        The node commands take a hash table of attributes, but it can be a memory and typing test to write it.
        Names are case sensitive so specifying blue works but Blue fails,
        Is the font name "courier New", "Courier new" or "Courier_New" ? Is the direction "back or backward"
        This function uses argument completers to fill in as many of the parameters as possible and converts
        values to lower case where needed.
      .example
      $edgeattr = New-EdgeAttr ibuteSet -direction both -arrowhead 'crow' -arrowtail  'lcrow' -color blue -fontname 'Calibri' -label "test"  -style dashed
      This defines a two way dashed arrow, in blue with a "crow" head and left-half-crow tail, with "test" as in black calibri as the style
      Note that the argument completer will help arrows in line with the grammar at http://www.graphviz.org/doc/info/arrows.html,
      only 42 of the 60 possible permuations are valid, and it allows double arrows but doesn't check for a redundant "none" in the sytle
    #>
    [CmdletBinding()]
    [Alias('EdgeAttributes')]
    Param(
        #Style of arrowhead on the head node of an edge. This will only appear if the dir attribute is "forward" or "both".
        [string]
        $arrowhead,
        #Multiplicative scale factor for arrowheads
        [double]
        $arrowsize,
        #Style of arrowhead on the tail node of an edge. This will only appear if the dir attribute is "back" or "both"
        [string]
        $arrowtail,
        #Basic drawing color for graphics, not text (which requires font color to be set)
        [string]
        $color,
        #If false, the edge is not used in ranking the nodes (defaults to true)
        [bool]
        $constraint,
        #Indicates which ends of the edge should be decorated with an arrowhead.
        [ValidateSet('forward','back','both','none')]
        [String]
        $direction,
        [string]
        #Color used for text.
        $fontcolor,
        #Font used for text.
        [string]
        $fontname,
        #Font size, in points, used for text.
        [double]
        $fontsize,
        #Text label to be placed near head of edge
        [string]
        $headlabel,
        #Text label attached to the edge
        [string]
        $label,
        #Color used for headlabel and taillabel. If not set, defaults to edge's fontcolor.
        [string]
        $labelfontcolor,
        #Font used for headlabel and taillabel. If not set, defaults to edge's fontname.
        [string]
        $labelfontname,
        #Font size, in points, used for headlabel and taillabel. If not set, defaults to edge's fontsize.
        [double]
        $labelfontsize,
        #Preferred edge length, in inches.
        [double]
        $length,
        #width of the pen, in points, used to draw lines and curves, including the boundaries of edges. It has no effect on text.
        [double]
        $penwidth,
        #Style for the edge, dashed, solid etc.
        [ValidateSet("dashed", "dotted", "solid", "invis", "bold" , "tapered")]
        [String]
        $style,
        #Text label to be placed near tail of edge.
        [string]
        $taillabel
    )
    $values = @{}
    #Attributes where name is shortened and doesn't match the parameter name
    if ($direction) {$values['dir'] = $direction.ToLower()}
    if ($length)    {$values['len'] = $length}
    #Attributes where graphviz expects all lower case and other case might have got through
    foreach ($param in @( 'arrowhead', 'arrowtail', 'color', 'fontcolor', 'labelfontcolor','style')) {
        if ($PSBoundParameters[$param]) {$values[$param] = $PSBoundParameters[$param].ToLower() }
    }
    #Attributes that can go through unchanged.
    foreach ($param in @( 'arrowsize', 'constraint', 'fontname',  'fontsize', 'headlabel',
                         'label', 'labelfontname', 'labelfontsize', 'penwidth', 'taillabel')) {
        if ($PSBoundParameters[$param]) {$values[$param] = $PSBoundParameters[$param].ToLower() }
    }

    $values
}


# .\PSGraph\Public\New-NodeAttributeSet.ps1

Function New-NodeAttributeSet {
    <#
      .synopsis
        Creates a set of attributes for the edge command.
      .description
        The edge commands takes a hash table of attributes, but it can be a memory and typing test to write it.
        Names are case sensitive so specifying blue works but Blue fails,
        Is the font name "courier New", "Courier new" or "Courier_New" ? Is the direction "back or backward"
        This function uses argument completers to fill in as many of the parameters as possible and converts
        values to lower case where needed.
      .example
      $edgeattr = New-EdgeAttributeSet -direction both -arrowhead 'crow' -arrowtail  'lcrow' -color blue -fontname 'Calibri' -label "test"  -style dashed
      This defines a two way dashed arrow, in blue with a "crow" head and left-half-crow tail, with "test" as in black calibri as the style
      Note that the argument completer will help arrows in line with the grammar at http://www.graphviz.org/doc/info/arrows.html,
      only 42 of the 60 possible permuations are valid, and it allows double arrows but doesn't check for a redundant "none" in the sytle
    #>
    [CmdletBinding()]
    [Alias('NodeAttributes')]
    Param(
        #Basic drawing color for graphics, not text (which requires font color to be set)
        [string]
        $color,
        #Distortion factor for shape=polygon. Positive values cause top part to be larger than bottom; negative values do the opposite.
        [double]
        $distortion,
        [string]
        $fillcolor,
        #If true, the node size is specified by the values of the width and height attributes only and is not expanded to contain the text label.
        #If the fixedsize attribute is set to shape, the width and height attributes also determine the size of the node shape, but the label can be much larger.
        [ValidateSet('false','shape','true')]
        [string]
        $fixedSize,
        #Color used for text.
        $fontcolor,
        #Font used for text.
        [string]
        $fontname,
        #Font size, in points, used for text.
        [double]
        $fontsize,
        #Height of node, in inches. This is taken as the initial, minimum height of the node
        $height,
        #Gives the name of a file containing an image to be displayed inside a node. The image file must be in one of the recognized formats, typically JPEG, PNG, GIF, BMP, SVG or Postscript, and be able to be converted into the desired output format.
        [string]
        $image,
        #Text label attached to the node
        [string]
        $label,
        #width of the pen, in points, used to draw lines and curves.
        [double]
        $penwidth,
        # force polygon to be regular, i.e., the vertices of the polygon will lie on a circle whose center is the center of the node.
        [switch]
        $regular,
        #Number of sides if shape=polygon.
        #A string specifying the shape of a node.
        [ValidateSet('box', 'polygon', 'ellipse', 'oval', 'circle', 'point', 'egg', 'triangle', 'plaintext', 'plain', 'diamond',
            'trapezium', 'parallelogram', 'house', 'pentagon', 'hexagon', 'septagon', 'octagon', 'doublecircle',
            'doubleoctagon', 'tripleoctagon', 'invtriangle', 'invtrapezium', 'invhouse', 'Mdiamond', 'Msquare',
            'Mcircle', 'rect', 'rectangle', 'square', 'star', 'none', 'underline', 'cylinder', 'note', 'tab',
            'folder', 'box3d', 'component', 'promoter', 'cds', 'terminator', 'utr', 'primersite', 'restrictionsite',
            'fivepoverhang', 'threepoverhang', 'noverhang', 'assembly', 'signature', 'insulator', 'ribosite',
            'rnastab', 'proteasesite', 'proteinstab', 'rpromoter', 'rarrow', 'larrow', 'lpromoter')]
        [string]
        $Shape,[int16]
        $sides,
        #Skew factor for shape=polygon. Positive values skew top of polygon to right; negative to left.
        [double]
        $skew,
        #Style for the edge, dashed, solid etc.
        [ValidateSet("dashed", "dotted", "solid", "invis", "bold" , "filled", "striped", "wedged", "diagonals", "rounded")]
        [String]
        $style,

        #Width of node, in inches. This is taken as the initial, minimum width of the node.
        [double]
        $width
    )
    $values = @{}
    #Attributes where name is shortened and doesn't match the parameter name
    if ($regular)   {$values['regular'] = $true}
    #Attributes where graphviz expects all lower case and other case might have got through
    foreach ($param in @( 'color', 'fillcolor', 'fixedsize', 'fontcolor', 'shape', 'style')) {
        if ($PSBoundParameters[$param]) {$values[$param] = $PSBoundParameters[$param].ToLower() }
    }
    #Attributes that can go through unchanged.
    foreach ($param in @( ' $distortion', 'fontname',  'fontsize', 'height', 'image',
                         'label', 'penwidth', 'sides', 'skew')) {
        if ($PSBoundParameters[$param]) {$values[$param] = $PSBoundParameters[$param].ToLower() }
    }

    $values
}

function arrowStyles {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $baseArrows = @('box', 'crow', 'curve', 'diamond', 'dot', 'inv', 'none', 'normal', 'tee', 'vee')
    $doubleArrowRegex =  "^[olr]*(" + ($basearrows -join "|") + ")[olr]*(?=\w+)"
    if ($wordToComplete -match $doubleArrowRegex) {
       $arrows = foreach ($a in $baseArrows ) {$Matches[0] + $a}
    }
    elseif ($wordToComplete -match '^ol|^or|^o|^l|^r' ) {
        $arrows = foreach ($a in $baseArrows ) {$Matches[0] + $a}
    }
    else {$arrows = $baseArrows}
    $arrows.Where({$_ -like "$wordToComplete*"}) | ForEach-Object {
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList "'$_'" , $_ ,
        ([System.Management.Automation.CompletionResultType]::ParameterValue) , $_
    }
}

function ColorCompletion {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    [System.Drawing.KnownColor].GetFields() | Where-Object {$_.IsStatic -and -not $_.IsSpecialName -and $_.name -like "$wordToComplete*" } |
        Sort-Object name | ForEach-Object {New-CompletionResult $_.name.ToLower() $_.name.ToLower()
    }
}

function ListFonts {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    if (-not $script:FontFamilies) {
        $script:FontFamilies = @("","")
        try {
            $script:FontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families.Name
        }
        catch {}
    }
    $script:FontFamilies.where({$_ -Gt "" -and $_ -like "$wordToComplete*"} ) | ForEach-Object {
        New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList "'$_'" , $_ ,
        ([System.Management.Automation.CompletionResultType]::ParameterValue) , $_
    }
}

if (Get-Command -Name register-argumentCompleter -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName arrowhead      -ScriptBlock $Function:arrowStyles
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName arrowtail      -ScriptBlock $Function:arrowStyles
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName color          -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName fontcolor      -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName labelfontcolor -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName labelfontname  -ScriptBlock $Function:ListFonts
    Register-ArgumentCompleter -CommandName New-EdgeAttributeSet              -ParameterName fontname       -ScriptBlock $Function:ListFonts
    Register-ArgumentCompleter -CommandName New-NodeAttributeSet              -ParameterName fontname       -ScriptBlock $Function:ListFonts
    Register-ArgumentCompleter -CommandName New-NodeAttributeSet              -ParameterName fontcolor      -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName New-NodeAttributeSet              -ParameterName color          -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName New-NodeAttributeSet              -ParameterName fillcolor      -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName record                            -ParameterName fillcolor      -ScriptBlock $Function:ColorCompletion
    Register-ArgumentCompleter -CommandName record                            -ParameterName fontname       -ScriptBlock $Function:ListFonts
}
# .\PSGraph\Public\Node.ps1
function Node
{
    <#
        .Description
        Used to specify a nodes attributes or placement within the flow.

        .Example
        graph g {
            node one,two,three
        }

        .Example
        graph g {
            node top @{shape='house'}
            node middle
            node bottom @{shape='invhouse'}
            edge top,middle,bottom
        }

        .Example

        graph g {
            node (1..10)
        }

        .Notes
        I had conflits trying to alias Get-Node to node, so I droped the verb from the name.
        If you have subgraphs, it works best to define the node inside the subgraph before giving it an edge
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
    [cmdletbinding()]
    param(
        # The name of the node
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0
        )]
        [object[]]
        $Name = 'node',

        # Script to run on each node
        [Parameter()]
        [alias('Script')]
        [scriptblock]
        $NodeScript = {$_},

        # Node attributes to apply to this node
        [Parameter(Position = 1)]
        [hashtable]
        $Attributes = @{},

        #Specify the the shape for the node - graphviz selects oval by default
        [Parameter()]
        [ValidateSet('box', 'polygon', 'ellipse', 'oval', 'circle', 'point', 'egg', 'triangle', 'plaintext', 'plain', 'diamond',
                     'trapezium', 'parallelogram', 'house', 'pentagon', 'hexagon', 'septagon', 'octagon', 'doublecircle',
                     'doubleoctagon', 'tripleoctagon', 'invtriangle', 'invtrapezium', 'invhouse', 'Mdiamond', 'Msquare',
                     'Mcircle', 'rect', 'rectangle', 'square', 'star', 'none', 'underline', 'cylinder', 'note', 'tab',
                     'folder', 'box3d', 'component', 'promoter', 'cds', 'terminator', 'utr', 'primersite', 'restrictionsite',
                     'fivepoverhang', 'threepoverhang', 'noverhang', 'assembly', 'signature', 'insulator', 'ribosite',
                     'rnastab', 'proteasesite', 'proteinstab', 'rpromoter', 'rarrow', 'larrow', 'lpromoter')]
        [string]
        $Shape,

        [Parameter()]
        [string]
        $Label,

        # When multiple nodes are supplied, automatically add them nodes to a rank
        [Parameter()]
        [alias('Rank')]
        [switch]
        $Ranked,

        # not used anymore but offers backward compatibility or verbosity
        [switch]
        $Default
    )
    begin
    {
         #re-create any scriptblock passed as a parameter, otherwise variables in this function are out of its scope.
        if ($NodeScript)
        {
            $Nodescript = [scriptblock]::create( $NodeScript )
        }
    }
    process
    {
        try
        {

            if (
                $Name.count -eq 1 -and
                $Name[0] -is [hashtable] -and
                !$PSBoundParameters.ContainsKey( 'NodeScript' )
            )
            {
                # detected attept to set default values in this form 'node @{key=value}', the hashtable ends up in $name[0]
                $Attributes = $Name[0]
                $Name[0] = 'node'
            }
            # don't want to add every attribute as a parameter just the most common for a node Changed handling when the sole parameter holds attributes to make this easier
            #Turn Shape or Label into Attributes - and allow for label being an empty string (i.e. boolean False !)
            if ($PSBoundParameters.ContainsKey('Label')) {
                $Attributes['label'] = $label
            }
            if ($PSBoundParameters.ContainsKey('Shape')) {
                $Attributes['shape'] = $Shape.ToLower()
            }
            $nodeList = @()
            foreach ( $node in $Name )
            {
                if ( $NodeScript )
                {
                    $nodeName = (@($node).ForEach($NodeScript))
                }
                else
                {
                    $nodeName = $node
                }


                $GraphVizAttribute = ConvertTo-GraphVizAttribute -Attributes $Attributes -InputObject $node
                '{0}{1} {2}' -f (Get-Indent), (Format-Value $nodeName -Node), $GraphVizAttribute

                $nodeList += $nodeName
            }

            if ($Ranked -and $null -ne $nodeList -and $nodeList.count -gt 1)
            {
                Rank -Nodes $nodeList
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\Rank.ps1
function Rank
{
    <#
        .Description
        Places specified nodes at the same level on the chart as a way to give some guidance to node layout

        .Example
        graph g {
            rank 1,3,5,7
            rank 2,4,6,8
            edge (1..8)
        }

        .Example
        $odd = @(1,3,5,7)
        $even = @(2,4,6,8)

        graph g {
            rank $odd
            rank $even
            edge $odd -to $even
        }

        .Notes
        Accepts an array of items or a list of strings.
    #>

    [cmdletbinding()]
    param(

        # List of nodes to be on the same level as each other
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0
        )]
        [object[]]
        $Nodes,

        # Used to catch alternate style of specifying nodes
        [Parameter(
            ValueFromRemainingArguments = $true,
            Position = 1
        )]
        [object[]]
        $AdditionalNodes,

        # Script to run on each node
        [alias('Script')]
        [scriptblock]
        $NodeScript = {$_}
    )

    begin
    {
        $values = @()
    }

    process
    {
        try
        {

            $itemList = New-Object System.Collections.Queue
            if ( $null -ne $Nodes )
            {
                $Nodes | ForEach-Object {$_} | ForEach-Object {$itemList.Enqueue($_)}
            }
            if ( $null -ne $AdditionalNodes )
            {
                $AdditionalNodes | ForEach-Object {$_} | ForEach-Object {$_} | ForEach-Object {$itemList.Enqueue($_)}
            }

            $Values += foreach ($item in $itemList)
            {
                # Adding these arrays ceates an empty element that we want to exclude
                if ( -Not [string]::IsNullOrWhiteSpace( $item ) )
                {
                    if ( $NodeScript )
                    {
                        $nodeName = [string]( @( $item ).ForEach( $NodeScript ) )
                    }
                    else
                    {
                        $nodeName = $item
                    }

                    Format-Value $nodeName -Node
                }
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    end
    {
        '{0}{{ rank=same;  {1}; }}' -f (Get-Indent), ($values -join '; ')
    }
}

# .\PSGraph\Public\Record.ps1

function Record
{
    <#
    .SYNOPSIS
    Creates a record object

    .DESCRIPTION
    Creates a record object that contains rows of data.

    .PARAMETER Name
    The node name for this record

    .PARAMETER Row
    An array of strings/objects to place in this record

    .PARAMETER RowScript
    A script to run on each row

    .PARAMETER ScriptBlock
    A sub expression that contains Row commands

    .PARAMETER Label
    The label to use for the header of the record, will default to the name if not set

    .PARAMETER TitlePosition
    Specifies where the label should appear, either top, bottom or none.

    .PARAMETER TableStyle
    Formatting applied to the table displaying the record, defaults to 'CELLBORDER="1" BORDER="0" CELLSPACING="0"',

    .PARAMETER TitleSpan
    Specifies the number of columns the title should span, if the rows in the record have multiple columns.

    .PARAMETER FontName
    Specifies the font to use for the record, defaults to "Courier New"

    .PARAMETER FillColor
    Background color for the record, defaults to "white"

    .EXAMPLE
    graph {

        Record Components1 @(
            'Name'
            'Environment'
            'Test <I>[string]</I>'
        )

        Record Components2 {
            Row Name
            Row 'Environment <B>test</B>'
            'Test'
        }

        Edge Components1:Name -to Components2:Name


        Echo one two three | Record Fish
        Record Cow red,blue,green

    } | Export-PSGraph -ShowGraph

    .NOTES
    Early release version of this command.
    A lot of stuff is hard coded that should be exposed as attributes

    #>
    [OutputType('System.String')]
    [cmdletbinding(DefaultParameterSetName = 'Script')]
    param(
        [Parameter(
            Mandatory,
            Position = 0
        )]
        [alias('ID', 'Node')]
        [string]
        $Name,

        [Parameter(
            Position = 1,
            ValueFromPipeline,
            ParameterSetName = 'Strings'
        )]
        [alias('Rows')]
        [Object[]]
        $Row,

        [Parameter(
            Position = 1,
            ParameterSetName = 'Script'
        )]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(
            Position = 2
        )]
        [ScriptBlock]
        $RowScript,

        [string]
        $Label,

        [string]
        $TableStyle = 'CELLBORDER="1" BORDER="0" CELLSPACING="0"',

        [string]
        $fontName = "Courier New",

        [string]
        $FillColor = "white",

        [int16]
        $TitleSpan,

        [ValidateSet('Top','Bottom','None')]
        [string]
        $TitlePosition = 'Top'
    )
    begin
    {
        $tableData = [System.Collections.ArrayList]::new()
        if ( [string]::IsNullOrEmpty($Label) )
        {
            $Label = $Name
        }
        #re-create scriptblock passed as a parameter, otherwise variables in this function are out of its scope.
        if ($RowScript)
        {
            $RowScript   = [scriptblock]::create( $RowScript )
        }
    }
    process
    {
        if ( $null -ne $ScriptBlock )
        {
            $Row = $ScriptBlock.Invoke()
        }

        foreach ( $node in $Row )
        {
            #Collapsed multiple loops into one. Name will be empty UNLESS the script sets it.
            $RowName = ""
            if ( $null -ne $RowScript )
            {
                @($node).ForEach($RowScript)
            }
            [void]$tableData.Add((Row -Label $node -Name $Rowname))
        }
    }
    end
    {
        $Colspan = if ($TitleSpan) {'COLSPAN="{0}"' -f $TitleSpan} else { "" }
        $html = switch ($TitlePosition) {
            'None'   {'<TABLE {0}>{1}</TABLE>' -f $TableStyle, ($tableData -join '')}
            'Bottom' {'<TABLE {0}>{1}<TR><TD bgcolor="black" align="center" {2}><font color="white"><B>{3}</B></font></TD></TR></TABLE>' -f $TableStyle, ($tableData -join ''),$Colspan,$Label}
             Default {'<TABLE {0}><TR><TD bgcolor="black" align="center" {2}><font color="white"><B>{3}</B></font></TD></TR>{1}</TABLE>' -f $TableStyle, ($tableData -join ''),$Colspan,$Label}
        }
        Node $Name @{label = $html; shape = 'none'; fontname = $fontName; style = "filled"; penwidth = 1; fillcolor =$FillColor }
    }
}

# .\PSGraph\Public\Row.ps1
function Row
{
    <#
    .SYNOPSIS
    Adds a row to a record

    .Description
    Adds a row to a record inside a PSGraph Graph

    .PARAMETER Label
    This is the displayed data for the row

    .PARAMETER Name
    This is the target name of this row to be used in edges.
    Will default to the label if the label has not special characters

    .PARAMETER HtmlEncode
    This will encode unintentional HTML. Characters like <>& would break html parsing if they are
    contained in the source data.

    .EXAMPLE
    graph {

        Record Components1 @(
            'Name'
            'Environment'
            'Test <I>[string]</I>'
        )

        Record Components2 {
            Row Name
            Row 'Environment <B>test</B>'
            'Test'
        }


        Edge Components1:Name -to Components2:Name

    } | Export-PSGraph -ShowGraph

    .NOTES
    Need to add attribute support

    DSL planned syntax
    # Row Label
    # Row Label -ID
    # Row Label Attributes
    # Row Label -ID Attributes

    #>
    [OutputType('System.String')]
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [string]
        $Label,

        [alias('ID')]
        [string]
        $Name,

        [switch]
        $HtmlEncode
    )
    process
    {
        if ( [string]::IsNullOrEmpty($Name) )
        {
            if ($Label -notmatch '[<,>\s]')
            {
                $Name = $Label
            }
            else
            {
                $Name = New-Guid
            }
        }

        if ($Label -match '^<TR>.*</TR>?')
        {
            $Label
        }
        else
        {
            if ($HtmlEncode)
            {
                $Label = ([System.Net.WebUtility]::HtmlEncode($Label))
            }
            '<TR><TD PORT="{0}" ALIGN="LEFT">{1}</TD></TR>' -f $Name, $Label
        }
    }
}
# .\PSGraph\Public\Set-NodeFormatScript.ps1
function Set-NodeFormatScript
{
    <#
        .Description
        Allows the definition of a custom node format

        .Example
        Set-NodeFormatScript -ScriptBlock {$_.ToLower()}

        .Notes
        This can be used if different datasets are not consistent.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(

        # The Scriptblock used to process every node value
        [ScriptBlock]
        $ScriptBlock = {$_}
    )

    process
    {
        try
        {
            if ( $PSCmdlet.ShouldProcess( 'Change default code id format function' ) )
            {
                $Script:CustomFormat = $ScriptBlock
            }
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\Show-PSGraph.ps1
function Show-PSGraph
{
    <#

    .ForwardHelpTargetName Export-PSGraph
    .ForwardHelpCategory Function
    .Notes
    To regenerate most of this proxy function
    $MetaData = New-Object System.Management.Automation.CommandMetaData (Get-Command  Export-PSGraph)
    $proxy = [System.Management.Automation.ProxyCommand]::Create($MetaData)

    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [Alias('InputObject', 'Graph', 'SourcePath')]
        [string[]]
        ${Source},

        [Parameter(Position = 0)]
        [string]
        ${DestinationPath},

        [ValidateSet('jpg', 'png', 'gif', 'imap', 'cmapx', 'jp2', 'json', 'pdf', 'plain', 'dot', 'svg')]
        [string]
        ${OutputFormat},

        [ValidateSet('Hierarchical', 'SpringModelSmall', 'SpringModelMedium', 'SpringModelLarge', 'Radial', 'Circular', 'dot', 'neato', 'fdp', 'sfdp', 'twopi', 'circo')]
        [string]
        ${LayoutEngine},

        [string[]]
        ${GraphVizPath}
    )

    begin
    {
        try
        {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Export-PSGraph', [System.Management.Automation.CommandTypes]::Function)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters -ShowGraph }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline()
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    process
    {
        try
        {
            $steppablePipeline.Process($_)
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }

    end
    {
        try
        {
            $steppablePipeline.End()
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}
# .\PSGraph\Public\SubGraph.ps1
function SubGraph
{
    <#
        .Description
        A graph that is nested inside another graph to sub group elements

        .Example
        graph g {
            node top,bottom @{shape='rect'}
            subgraph 0 {
                node left,right
            }
            edge top -to left,right
            edge left,right -to bottom
        }

        .Notes
        This is just like the graph or digraph, except the name must match cluster_#
        The numbering must start at 0 and work up or the processor will fail.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
    [cmdletbinding(DefaultParameterSetName = 'Default')]
    param(
        # Name of subgraph
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Named'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'NamedAttributes'
        )]
        [alias('ID')]
        $Name,

        # The commands to execute inside the subgraph
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Default'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Named'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Attributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 2,
            ParameterSetName = 'NamedAttributes'
        )]
        [scriptblock]
        $ScriptBlock,

        # Hashtable that gets translated to graph attributes
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'NamedAttributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Attributes'
        )]
        [hashtable]
        $Attributes = @{}
    )

    process
    {
        try
        {
            if ( $null -eq $Name )
            {
                $name = ((New-Guid ) -split '-')[4]
            }

            Graph -Name "cluster$Name" -ScriptBlock $ScriptBlock -Attributes $Attributes -Type 'subgraph'
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError( $PSitem )
        }
    }
}

# .\PSGraph\Public\svg.ps1
function svg {
    <#
      .Description
        Wraps the graph and export graph functions to generate a graph in one go
        has aliases cmapxGraph, DiGraph, dotGraph, gifGraph, imapGraph, jp2Graph, jpgGraph, jsonGraph, pdfGraph, plainGraph, pngGraph, svgGraph
        to output different kinds of graph
      .Example
        svg -ShowGraph  { Node $PWD @{label = $Html; shape = 'none';}}
        This creates a single node graph (although the script block could be much longer).
        The graph is output to a SVG file with a  system generated name in the TEMP folder and opened in the default viewer
        Here $html contains a table which describes the current directory.
        .Example
        jpgGraph "$env:USERPROFILE\documents\graph" { Node $PWD @{label = $H  ; shape = 'none'; fontname = "Consolas"; }}
        This creates the same graph as before but this time the command is called using the jpgGraph alias, so the output is
        in JPG format. A file name is given but because it does not in in .jpg, that will be added
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute( "PSAvoidDefaultValueForMandatoryParameter", "" )]
    [CmdletBinding( DefaultParameterSetName = 'Default' )]
    [Alias( 'DiGraph' )]
    [OutputType( [string] )]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Path'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'PathAttributes'
        )]
        [Alias('Path')]
        [string]
        $DestinationPath,

        # The commands to execute inside the graph
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Default'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Path'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Attributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 2,
            ParameterSetName = 'PathAttributes'
        )]
        [scriptblock]
        $ScriptBlock,

        # Hashtable that gets translated to graph attributes
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'PathAttributes'
        )]
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Attributes'
        )]
        [hashtable]
        $Attributes = @{},

        # Keyword that initiates the graph
        [string]
        $Type ,

        # Name or ID of the graph
        [string]$Name ,

        # The layout engine used to generate the image
        [ValidateSet(
            'Hierarchical',
            'SpringModelSmall' ,
            'SpringModelMedium',
            'SpringModelLarge',
            'Radial',
            'Circular',
            'dot',
            'neato',
            'fdp',
            'sfdp',
            'twopi',
            'circo'
        )]
        [string]
        $LayoutEngine,

        [Parameter()]
        [string[]]
        $GraphVizPath,


        # launches the graph when done
        [switch]
        $ShowGraph
    )

    if (-not $PSBoundParameters.ContainsKey('Name')) {$PSBoundParameters['Name'] = 'PSGraph'}
    $format = $MyInvocation.InvocationName.replace('Graph','').ToLower()
    $exportParams = @{OutputFormat = $format }
    if ($DestinationPath -and $format -in @('dot','gif','jpg','png', 'pdf', 'svg') -and $DestinationPath -notmatch "\.$format$") {
        $PSBoundParameters['DestinationPath'] += ".$format"
    }
    foreach ($var in 'ShowGraph', 'GraphVizPath', 'LayoutEngine','DestinationPath') {
        if  ($PSBoundParameters.ContainsKey($var)) {
            $exportParams[$var] = $PSBoundParameters[$var]
            [void]$PSBoundParameters.Remove($var)
        }
    }
    graph @PSBoundParameters  | Export-PSGraph @exportParams
}


foreach ($outputType in @('jpg', 'png', 'gif', 'imap', 'cmapx', 'jp2', 'json', 'pdf', 'plain', 'dot','svg')) {
    New-Alias -Name "$outputType`Graph" -Value svg -Force -Scope  Global
}


