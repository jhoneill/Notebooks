#region plotly layout components
function New-PlotlyFont  {
    [Alias("font")]
    [outputType([XPlot.Plotly.Font])]
    param (
        $Size,
        [string]$color,
        [string]$family
    )
    New-Object -TypeName XPlot.Plotly.Font -Property $PSBoundParameters
}

function New-PlotlyLegend {
    [alias('legend')]
    [outputType([XPlot.Plotly.Legend])]
    param (
        $x,
        $y,
        [string]$bgcolor,
        [string]$borderColor
    )
    New-Object -TypeName XPlot.Plotly.Legend -Property $PSBoundParameters
}

function New-PlotlyLine {
    [alias('Line')]
    [outputType([XPlot.Plotly.Line])]
    Param (
        [string]$color ,
        $width
        #shape smoothing dash colorscale cauto cmax cmin autocolorscale reversescale
    )
    New-Object -TypeName XPlot.Plotly.Line -Property $PSBoundParameters
}

function New-PlotlyMargin {
    [alias("margin")]
    [outputType([XPlot.Plotly.Margin])]
    param ($l , $r, $b ,$t, $pad) #autoexpand
    New-Object -TypeName XPlot.Plotly.Margin -Property $PSBoundParameters
}

function New-PlotlyMarker {
    [alias('Marker')]
    [outputType([XPlot.Plotly.Marker])]
    Param (
        $Color,
        $size,
        [ValidateSet(
        "circle", "circle-open", "circle-dot", "circle-open-dot",
        "square", "square-open", "square-dot", "square-open-dot",
        "diamond", "diamond-open", "diamond-dot", "diamond-open-dot",
        "cross", "cross-open", "cross-dot", "cross-open-dot",
        "x", "x-open", "x-dot", "x-open-dot",
        "triangle-up", "triangle-up-open", "triangle-up-dot", "triangle-up-open-dot",
        "triangle-down", "triangle-down-open", "triangle-down-dot", "triangle-down-open-dot",
        "triangle-left", "triangle-left-open", "triangle-left-dot", "triangle-left-open-dot",
        "triangle-right", "triangle-right-open", "triangle-right-dot", "triangle-right-open-dot",
        "triangle-ne", "triangle-ne-open", "triangle-ne-dot", "triangle-ne-open-dot",
        "triangle-se", "triangle-se-open", "triangle-se-dot", "triangle-se-open-dot",
        "triangle-sw", "triangle-sw-open", "triangle-sw-dot", "triangle-sw-open-dot",
        "triangle-nw", "triangle-nw-open", "triangle-nw-dot", "triangle-nw-open-dot",
        "pentagon", "pentagon-open", "pentagon-dot", "pentagon-open-dot",
        "hexagon", "hexagon-open", "hexagon-dot", "hexagon-open-dot",
        "hexagon2", "hexagon2-open", "hexagon2-dot", "hexagon2-open-dot",
        "octagon", "octagon-open", "octagon-dot", "octagon-open-dot",
        "star", "star-open", "star-dot", "star-open-dot",
        "hexagram", "hexagram-open", "hexagram-dot", "hexagram-open-dot",
        "star-triangle-up", "star-triangle-up-open", "star-triangle-up-dot", "star-triangle-up-open-dot",
        "star-triangle-down", "star-triangle-down-open", "star-triangle-down-dot", "star-triangle-down-open-dot",
        "star-square", "star-square-open", "star-square-dot", "star-square-open-dot",
        "star-diamond","star-diamond-open", "star-diamond-dot", "star-diamond-open-dot",
        "diamond-tall", "diamond-tall-open", "diamond-tall-dot", "diamond-tall-open-dot",
        "diamond-wide", "diamond-wide-open", "diamond-wide-dot", "diamond-wide-open-dot",
        "hash", "hash-open", "hash-dot", "hash-open-dot",
        "hourglass", "hourglass-open",              "bowtie", "bowtie-open",
         "circle-cross", "circle-cross-open",       "circle-x", "circle-x-open",
         "square-cross", "square-cross-open", "square-x", "square-x-open",
         "diamond-cross", "diamond-cross-open",     "diamond-x", "diamond-x-open",
         "cross-thin", "cross-thin-open",           "x-thin", "x-thin-open",
         "asterisk", "asterisk-open",
         "y-up", "y-up-open", "y-down", "y-down-open", "y-left", "y-left-open", "y-right", "y-right-open",
         "line-ew", "line-ew-open", "line-ns", "line-ns-open", "line-ne", "line-ne-open", "line-nw", "line-nw-open",
         "arrow-up", "arrow-up-open", "arrow-down", "arrow-down-open", "arrow-left", "arrow-left-open", "arrow-right", "arrow-right-open",
         "arrow-bar-up", "arrow-bar-up-open", "arrow-bar-down", "arrow-bar-down-open", "arrow-bar-left", "arrow-bar-left-open", "arrow-bar-right", "arrow-bar-right-open"
         )]
        [string]$symbol,
        $Line,
        $opacity)
     if ($Line -is [hashtable]) {$PSBoundParameters['Line'] = New-Object -TypeName XPlot.Plotly.Line -Property $Line}
     New-Object -TypeName XPlot.Plotly.Marker -Property $PSBoundParameters
}

function New-PlotlyXbins {
    [alias('xbins')]
    [outputType([XPlot.Plotly.xbins])]
    param ($start, $end, $size)
    new-object -typename xplot.plotly.xbins -property $psboundparameters
}

function New-PlotlyYbins {
    [alias('ybins')]
    [outputType([XPlot.Plotly.ybins])]
    param ($start, $end, $size)
    new-object -typename xplot.plotly.ybins -property $psboundparameters
}
#endregion

#region plotly Axes
function New-PlotlyColorBar {
    [Alias("ColorBar")]
    [outputType([XPlot.Plotly.Colorbar])]
    Param (
        [string]$title,
        $titleFont,
        $TickVals,
        $Tick0,
        $dTick,
        $nTicks,
        $TickText,
        $TickColor,
        $tickangle,
        [ValidateSet("auto","linear", "array")]
        $tickmode,
        $TickFont,
        [bool]$showTickLabels ,
        [string]$tickprefix,
        [string]$ticksuffix,
        $BorderColor,
        $Borderwidth,
        $Showexponent,
        [ValidateSet("none", "e", "E", "power", "SI", "B")]
        [string]$ExponentFormat
    )
    if ($tickFont   -is [hashtable]) {$PSBoundParameters['tickFont']   = New-Object -TypeName XPlot.Plotly.Font    -Property $tickFont}
    if ($titleFont  -is [hashtable]) {$PSBoundParameters['titleFont']  = New-Object -TypeName XPlot.Plotly.Font    -Property $titleFont}
    New-Object -TypeName XPlot.Plotly.Colorbar -Property $PSBoundParameters
}

function New-PlotlyXaxis {
    [alias('xaxis')]
    [outputType([XPlot.Plotly.Xaxis])]
    param (
        [string]$title,
        $titleFont,
        $tickFont,
        [string]$tickcolor,
        $tickLen,
        $tickWidth,
        [bool]$showTickLabels ,
        [string]$tickprefix,
        [string]$ticksuffix,
        $Showexponent,
        [ValidateSet("none", "e", "E", "power", "SI", "B")]
        [string]$ExponentFormat,
        [ValidateSet("left","right")]
        [string]$side ,
        [bool]$ShowLine,
        $LineWidth,
        $LineColor,
        [bool]$showGrid,
        $GridWidth,
        $GridColor,
        [Bool]$ZeroLine,
        $ZerolineWidth,
        $ZerolineColor,
        [ValidateSet("-", "linear", "log", "date", "category", "multicategory")]
        [string]$type,
        [ValidateSet( "outside", "inside", "" )]
        [string]$ticks,
        $tickangle,
        [ValidateSet("auto","linear", "array")]
        $tickmode,
        $tick0,
        $dtick,
        [bool]$autotick, #tickmode nticks, tick0, dtick, tickVals, ticktext tickformat
        #true , false , reversed
        [Bool]$AutoRange
        #ranage, rangemode, fixedrange
        )
    if ($tickFont   -is [hashtable]) {$PSBoundParameters['tickFont']   = New-Object -TypeName XPlot.Plotly.Font    -Property $tickFont}
    if ($titleFont  -is [hashtable]) {$PSBoundParameters['titleFont']  = New-Object -TypeName XPlot.Plotly.Font    -Property $titleFont}
    New-Object -TypeName XPlot.Plotly.Xaxis -Property $PSBoundParameters
}

function New-PlotlyYaxis {
    [alias('yaxis')]
    [outputType([XPlot.Plotly.Yaxis])]
    param (
        [string]$title,
        $titleFont,
        $tickFont,
        [string]$tickcolor,
        $tickLen,
        $tickWidth,
        [bool]$showTickLabels ,
        [string]$tickprefix,
        [string]$ticksuffix,
        [ValidateSet("none", "e", "E", "power", "SI", "B")]
        [string]$ExponentFormat,
        [ValidateSet("top","bottom")]
        [string]$side ,
        [bool]$ShowLine,
        $LineWidth,
        $LineColor,
        [bool]$showGrid,
        $GridWidth,
        $GridColor,
        [Bool]$ZeroLine,
        $zerolinewidth,
        $zerolinecolor,
        [ValidateSet("-", "linear", "log", "date", "category", "multicategory")]
        [string]$type,
        [ValidateSet( "outside", "inside", "" )]
        [string]$ticks,
        $tickangle,
        [ValidateSet("auto","linear", "array")]
        $tickmode,
        $tick0,
        $dtick,
        [bool]$autotick,
        [Bool]$AutoRange
    )
    if ($tickFont   -is [hashtable]) {$PSBoundParameters['tickFont']   = New-Object -TypeName XPlot.Plotly.Font    -Property $tickFont}
    if ($titleFont  -is [hashtable]) {$PSBoundParameters['titleFont']  = New-Object -TypeName XPlot.Plotly.Font    -Property $titleFont}
    New-Object -TypeName XPlot.Plotly.Yaxis -Property $PSBoundParameters
}

function New-PlotlyAngularaxis {
    [alias('angularaxis')]
    [outputType([XPlot.Plotly.Angularaxis])]
    param (
        [string]$tickcolor,
        [string]$ticksuffix,
        [bool]$visible,
        [Bool]$showline,
        [Bool]$showtickLabels
    )
    New-Object -TypeName XPlot.Plotly.Angularaxis -Property $PSBoundParameters
}

function New-PlotlyRadialaxis {
    [alias('Radialaxis')]
    [outputType([XPlot.Plotly.Radialaxis])]
    param (
        [string]$tickcolor,
        [string]$ticksuffix,
        [bool]$visible,
        [Bool]$showline,
        [Bool]$showtickLabels
    )
    if ($tickFont   -is [hashtable]) {$PSBoundParameters['tickFont']   = New-Object -TypeName XPlot.Plotly.Font    -Property $tickFont}
    if ($titleFont  -is [hashtable]) {$PSBoundParameters['titleFont']  = New-Object -TypeName XPlot.Plotly.Font    -Property $titleFont}
    New-Object -TypeName XPlot.Plotly.Radialaxis -Property $PSBoundParameters
}

<#
      showtickprefix showticksuffix showexponent exponentformat tickformat showline linecolor linewidth  showgrid gridcolor gridwidth zeroline zerolinecolor zerolinewidth
      #type autorange rangemode  range fixedrange  tickmode nticks tick0 dtick tickvals ticktext ticks mirror ticklen tickwidth

        showgrid       = $True

      gridwidth      = 2
      gridcolor      = '#bdbdbd'

       showticklabels = $True
      tickangle      = 45
      tickmode       = 'linear'
      tick0          = 0.0
      dtick          = 0.25
}
#>
#endregion

function New-PlotlyLayout {
    [Alias("Layout")]
    [outputType([XPlot.Plotly.Layout+Layout])]
    param (
        [string]$Title,
         $TitleFont,
        $XAxis, #xaxis1        xaxis2

        $YAxis, #        yaxis2
        $AngularAxis,
        $RadialAxis,
        $Legend,
        $Font,
        $Barmode,
        $BarGap,
        $BarGroupGap,
        $BarGroup,
        $Boxmode,
        $Width,
        $Height,
        $Orientation, #direction
        $Margin,
        [string]$Paper_bgcolor,
        [string]$Plot_bgcolor,
        [bool]$Showlegend,
        [bool]$Autosize

        #annotations  https://plotly.com/python/reference/layout/annotations/
        #shapes  https://plotly.com/python/reference/layout/shapes/
        #separators hidesources smith dragmode hovermode scene geo #

    )
    if ($Margin      -is [hashtable]) {$PSBoundParameters['Margin']      = New-Object -TypeName XPlot.Plotly.Margin -Property $Margin}
    if ($Font        -is [hashtable]) {$PSBoundParameters['Font']        = New-Object -TypeName XPlot.Plotly.Font   -Property $Font}
    if ($Legend      -is [hashtable]) {$PSBoundParameters['Legend']      = New-Object -TypeName XPlot.Plotly.Legend -Property $Legend}
    if ($YAxis       -is [hashtable]) {$PSBoundParameters['YAxis']       = New-PlotlyYAxis       @YAxis}
    if ($XAxis       -is [hashtable]) {$PSBoundParameters['XAxis']       = New-PlotlyXAxis       @XAxis}
    if ($Radialaxis  -is [hashtable]) {$PSBoundParameters['Radialaxis']  = New-PlotlyRadialAxis  @Radialaxis}
    if ($Angularaxis -is [hashtable]) {$PSBoundParameters['Angularaxis'] = New-PlotlyAngularAxis @Angularaxis}
    New-Object -TypeName XPlot.Plotly.Layout+Layout -Property $PSBoundParameters
}

#region ploty "trace" objects i.e. graphs
#Note these could be built from a script using [XPlot.Plotly.Bar].DeclaredProperties.name etc

Function New-PlotlyXError {
    [alias('error_x')]
    [outputType([XPlot.Plotly.Error_x])]
    param(
    [ValidateSet("percent", "constant", "sqrt", "data")]
    $Type,
    [bool]$Symmetric,
    [Parameter(ParameterSetName='Value',Mandatory=$true)]
    $Value,
    [Parameter(ParameterSetName='Value')]
    $ValueMinus,
    [Parameter(ParameterSetName='Array',Mandatory=$true)]
    $Array,
    [Parameter(ParameterSetName='Array')]
    $ArrayMinus,
    $Color,
    $Thickness,
    $width
    )
    New-Object -TypeName XPlot.Plotly.Error_x -Property $PSBoundParameters
}

Function New-PlotlyYError {
    [alias('error_y')]
    [outputType([XPlot.Plotly.Error_y])]
    param(
    [ValidateSet("percent", "constant", "sqrt", "data")]
    $Type,
    [bool]$Symmetric,
    [Parameter(ParameterSetName='Value',Mandatory=$true)]
    $Value,
    [Parameter(ParameterSetName='Value')]
    $ValueMinus,
    [Parameter(ParameterSetName='Array',Mandatory=$true)]
    $Array,
    [Parameter(ParameterSetName='Array')]
    $ArrayMinus,
    $Color,
    $Thickness,
    $width
    )
    New-Object -TypeName XPlot.Plotly.Error_Y -Property $PSBoundParameters
}

function New-PlotlyAreaTrace {
    [alias('Area')]
    [outputType([XPlot.Plotly.Area])]
    param (
        $r,
        $t,
        $name,
        $Marker
    )
    if ($Marker -is [hashtable]) {$PSBoundParameters['Marker'] = New-PlotlyMarker @Marker}
    New-Object -TypeName XPlot.Plotly.Area -Property $PSBoundParameters
}

function New-PlotlyBarTrace {
    [alias('Bar')]
    [outputType([XPlot.Plotly.Bar])]
    Param ($x,
           $y,
           [string]$name,
           $Marker,
           $Orientation
    )
    if ($Marker -is [hashtable]) {$PSBoundParameters['Marker'] = New-PlotlyMarker @Marker}
     New-Object -TypeName XPlot.Plotly.Bar -Property $PSBoundParameters
}

function New-PlotlyBoxTrace {
    [alias('Box')]
    [outputType([XPlot.Plotly.Box])]
    param (
        $x,
        $y,
        $Name,
        [string]$boxpoints,
        $Jitter,
        $PointPos ,
        $Marker
    )
    if ($Marker -is [hashtable]) {$PSBoundParameters['Marker'] = New-PlotlyMarker @Marker}
    New-Object -TypeName XPlot.Plotly.Box -Property $PSBoundParameters
}

function NewPlotlyCandlestickTrace {
    [alias('Candlestick')]
    [outputType([XPlot.Plotly.Candlestick])]
    param (
        $x,
        $open,
        $close,
        $high,
        $low,
        $Text
    )
    New-Object -TypeName XPlot.Plotly.Candlestick -Property $PSBoundParameters
}

function New-PlotlyContourTrace {
    [cmdletbinding(DefaultParameterSetName="NoXorY")]
    [Alias('Contour')]
    [outputType([XPlot.Plotly.Heatmap])]
    Param (
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=0)]
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $x,  # array of xpoints or specify first, x0, & delta dx
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $x0,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $dx,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=1)]
        $y,  # array of xpoints or specify first, y0. & delta dy
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $y0,
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $dy,
        $z,
        [validateset(
            'aggrnyl',	'agsunset',	'blackbody',	'bluered',	'blues',	    'blugrn',	'bluyl',	'brwnyl',
            'bugn',	    'bupu',	    'burg',	        'burgyl',	'cividis',  	'darkmint',	'electric',	'emrld',
            'gnbu',	    'greens',	'greys',	    'hot',	    'inferno',  	'jet',	    'magenta',	'magma',
            'mint',	    'orrd',	    'oranges',	    'oryel',	'peach',	    'pinkyl',	'plasma',	'plotly3',
            'pubu',	    'pubugn',	'purd',	        'purp', 	'purples',	    'purpor',	'rainbow',	'rdbu',
            'rdpu',	    'redor',	'reds',	        'sunset',	'sunsetdark',   'teal', 	'tealgrn',	'viridis',
            'ylgn',	    'ylgnbu',	'ylorbr',	    'ylorrd',	'algae',	    'amp',  	'deep', 	'dense',
            'gray',	    'haline',	'ice',      	'matter',	'solar',    	'speed',	'tempo',	'thermal',
            'turbid',   'armyrose', 'brbg',     	'earth',	'fall',	        'geyser',	'prgn', 	'piyg',
            'picnic',   'portland', 'puor',	        'rdgy', 	'rdylbu',	    'rdylgn',	'spectral',	'tealrose',
            'temps',    'tropic',	'balance',	    'curl',	    'delta',	    'edge', 	'hsv',  	'icefire',
            'phase',    'twilight', 'mrybm',	    'mygbm'
        )]
        [string]$ColorScale,
        $ColorBar
    )
    New-Object -TypeName XPlot.Plotly.Contour -Property $PSBoundParameters
}

function New-PlotlyHeatMapTrace {
    [cmdletbinding(DefaultParameterSetName="XAndY")]
    [alias('Heatmap')]
    [outputType([XPlot.Plotly.Heatmap])]
    param (
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=0)]
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $x,  # array of xpoints or specify first, x0, & delta dx
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $x0,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $dx,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=1)]
        $y,  # array of xpoints or specify first, y0. & delta dy
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $y0,
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $dy,
        #Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points.
        $z,
        $text,
        [ValidateSet('Greys', 'YlGnBu', 'Greens', 'YlOrRd', 'Bluered', 'RdBu', 'Reds', 'Blues', 'Picnic', 'Rainbow', 'Portland', 'Jet', 'Hot', 'Blackbody', 'Earth', 'Electric', 'Viridis', 'Cividis')]
        [string]$ColorScale,
        $ColorBar
    )
    if ($ColorBar -is [hashtable]) {$PSBoundParameters['ColorBar'] = New-PlotlyColorBar @ColorBar}
    New-Object -TypeName XPlot.Plotly.HeatMap -Property $PSBoundParameters
}

function New-PlotlyHistogramTrace {
    [Alias('Histogram')]
     [outputType([XPlot.Plotly.Histogram])]
    param(
        $x,
        $dx,
        $error_x,
        $y,
        $dy,
        $error_y,
        $z,
        $Name,
        [ValidateSet("count", "sum", "avg", "min", "max" )]
        $histFunc,
        $histnorm,
        $r,
        $t,
        $nbinsx,
        $nbinsy,
        $xbins,
        $ybins
    )
    if ($xbins -is [hashtable]) {$psboundparameters['xbins'] = New-PlotlyXbins @xbins}
    if ($ybins -is [hashtable]) {$psboundparameters['ybins'] = New-PlotlyYbins @ybins}
   New-Object -typename xplot.plotly.histogram -property $PSBoundParameters
}

function New-PlotlyPieTrace {
    [alias('Pie')]
    [outputType([XPlot.Plotly.Pie])]
    Param(
        $Values,
        $Labels
    )
    New-Object -TypeName XPlot.Plotly.Pie -Property $PSBoundParameters
}

function New-PlotlyScatterTrace {
    [cmdletbinding(DefaultParameterSetName="XAndY")]
    [alias('Scatter')]
    [outputType([XPlot.Plotly.Scatter])]
    param (
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=0)]
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $x,  # array of xpoints or specify first, x0, & delta dx
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $x0,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $dx,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=1)]
        $y,  # array of xpoints or specify first, y0. & delta dy
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $y0,
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $dy,
        #Sets text elements associated with each (x,y) pair. If a single string, the same string appears over all the data points.
        $Text,
        [Parameter(ParameterSetName="Polar",Mandatory=$true)]
        $r,
        [Parameter(ParameterSetName="Polar",Mandatory=$true,Position=1)]
        $t,
        $name,
        <#  Sets the area to fill with a solid color. Defaults to "none" unless this trace is stacked,
           then it gets "tonexty" ("tonextx") if `orientation` is "v" ("h")
           Use with `fillcolor` if not "none".
           "tozerox" and "tozeroy" fill to x=0 and y=0 respectively.
           "tonextx" and "tonexty" fill between the endpoints of this trace and the endpoints of the trace before it,
           connecting those endpoints with straight lines (to make a stacked area graph);
           if there is no trace before it, they behave like "tozerox" and "tozeroy". "toself" c
           onnects the endpoints of the trace (or each segment of the trace if it has gaps) into a closed shape.
           "tonext" fills the space between two traces if one completely encloses the other (eg consecutive contour lines),
           and behaves like "toself" if there is no trace before it. "tonext" should not be used if one trace does not enclose the other.
            Traces in a `stackgroup` will only fill to (or be filled to) other traces in the same group.
            With multiple `stackgroup`s or some traces stacked and some not, if fill-linked traces are not already consecutive,
           the later ones will be pushed down in the drawing order.#>
        [ValidateSet( "none" , "tozeroy" , "tozerox" , "tonexty" , "tonextx" , "toself" ,"tonext")]
        [string]$fill,
        [string]$fillColor,
        <#
        Determines the drawing mode for this scatter trace. If the provided `mode` includes "text" then the `text` elements appear at the coordinates.
        Otherwise, the `text` elements appear on hover. If there are less than 20 points and the trace is not stacked then the default is "lines+markers". Otherwise, "lines".
        #>
        [ValidateSet('none','lines','markers','text','lines+markers','lines+text','markers+text','lines+markers+text')]
        [string]$Mode,
        $Marker,
        $error_x,
        $error_y
    )
    if ($error_x -is [hashtable]) {$PSBoundParameters['error_x'] = New-PlotlyXError @error_x}
    if ($error_y -is [hashtable]) {$PSBoundParameters['error_y'] = New-PlotlyXError @error_y}
    if ($Marker  -is [hashtable]) {$PSBoundParameters['Marker']  = New-PlotlyMarker @Marker}
    New-Object -TypeName XPlot.Plotly.Scatter -Property $PSBoundParameters
}

function New-PlotlyScatter3DTrace {
    [cmdletbinding(DefaultParameterSetName="XAndY")]
    [alias('Scatter3D')]
    [outputType([XPlot.Plotly.Scatter3d])]
    param (
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=0)]
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true,Position=0)]
        $x,  # array of xpoints or specify first, x0, & delta dx
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $x0,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        $dx,
        [Parameter(ParameterSetName="YIncrementX",Mandatory=$true)]
        [Parameter(ParameterSetName="XAndY",      Mandatory=$true,Position=1)]
        $y,  # array of xpoints or specify first, y0. & delta dy
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true )]
        $y0,
        [Parameter(ParameterSetName="XIncrementY",Mandatory=$true )]
        $dy,
        $z,
        $text,
        $name,
        [string]$fill,
        [string]$Mode,
        $Marker
    )
    if ($Marker -is [hashtable]) {$PSBoundParameters['Marker'] = New-PlotlyMarker @Marker}
    New-Object -TypeName XPlot.Plotly.Scatter3d -Property $PSBoundParameters
}

function New-PlotlySurfaceTrace {
    [Alias('Surface')]
    [outputType([XPlot.Plotly.Surface])]
    Param (
        $x,  # array of xpoints or specify first, x0, & delta dx
        $y,  # array of xpoints or specify first, y0. & delta dy
        $z,
        [ValidateSet('Greys', 'YlGnBu', 'Greens', 'YlOrRd', 'Bluered', 'RdBu', 'Reds', 'Blues', 'Picnic', 'Rainbow', 'Portland', 'Jet', 'Hot', 'Blackbody', 'Earth', 'Electric', 'Viridis', 'Cividis')]
        [string]$ColorScale,
        $ColorBar
    )
    New-Object -TypeName XPlot.Plotly.Surface -Property $PSBoundParameters
}
#endregion

function plot {
    param   (
    [Parameter(ParameterSetName='ScriptBlock',Mandatory=$true, Position=0)]
    [Alias("sb")]
    [scriptblock]$ScriptBlock,
    [Parameter(ParameterSetName='Traces',Mandatory=$true, Position=0 ,ValueFromPipeline=$true)]
    [XPlot.Plotly.trace[]]$Trace,
    $Layout,
    [String]$Title = "",
    $Width,
    $Height
    )
    begin   {
        $traces = [System.Collections.Generic.List[XPlot.Plotly.Trace]]::new()
        if ($ScriptBlock) {
          Invoke-Command -ScriptBlock $ScriptBlock | ForEach-Object {$traces.Add($_) }
        }
        if ($Layout -is [hashtable] ) {$Layout = New-PlotlyLayout @Layout}
    }
    process {
        if ($Trace) { $trace | ForEach-Object {$traces.Add($_) }}
    }
    end     {
        $chart = [XPlot.Plotly.Chart]::Plot($traces)
        if ($Layout) {$chart.WithLayout($Layout)}
        if ($Title)  {$chart.WithTitle( $Title)}
        if ($Width)  {$chart.WithWidth( $width)}
        if ($Height) {$chart.WithHeight($Height)}
        Out-Display $chart
    }
}
