Import-module powershell-yaml -ErrorAction stop
Import-module ~\\Documents\GitHub\PSGraph\PSGraph\PSGraph.psd1         -ErrorAction stop

function plot_step {
    param ($Step)
    if ($Step.template) {
        $stepLabel = $step.template
        if ((++ $script:dupNames[$stepLabel]) -gt 1) {
            $stepLabel += ("_" + $script:dupNames[$stepLabel] )
        }
        Record -name $stepLabel {
            foreach ($p in $step.parameters.keys) {row ($p +": " + $Step.parameters[$p])}
        }
        edge $script:previous -To $stepLabel
        $script:previous      =   $stepLabel
    }
    else {
        $stepLabel  = $null
        if ($Step.displayName) {$stepLabel = $Step.displayName}
        if ($Step.task)        {$stepLabel = $Step.task -replace '@\d+$',''}
        if ($stepLabel) {
            if ((++ $script:dupNames[$stepLabel]) -gt 1) {
                $stepLabel += ("_" + $script:dupNames[$stepLabel] )
            }
            node $stepLabel
            edge $script:previous -To $stepLabel
            $script:previous = $stepLabel
        }
    }
}

function plot_job {
    Param ($Job)
    if ($Job.job) {
        $jobLabel = "Job: $($Job.job)"
        if ($job.pool.vmImage) {
            Record -Name $jobLabel {row $job.pool.vmImage }
        }
        else {node $jobLabel -Shape box }
        if ($script:previous) {edge $script:previous -to $jobLabel}
        $script:previous = $jobLabel
        foreach ($step in $Job.steps) {
           plot_step -step $step
        }
    }
    elseif ($Job.deployment) {
        record $Job.deployment {$Job.environment.name}
        if ($script:previous) {edge $script:previous -to $Job.deployment}
        $script:previous = $Job.deployment
        if (-not $job.strategy.runOnce.deploy.steps) {
            Write-Warning "$($job.deployment) doesn't have strategy/runonce/deploy/steps... can't parse it"
        }
        foreach ($step in $Job.strategy.runOnce.deploy.steps) {
            plot_step -step $step
        }
    }
}

function plot_stage {
    Param ($Stage, $Parent)
    if     ($Stage.template) {
        $StageLabel = $Stage.template
        if ((++ $script:dupNames[$Stage.template]) -gt 1) {
            $StageLabel += ("_" + $script:dupNames[$Stage.template])
        }
        subgraph -Attributes @{rankDir='LR' } -ScriptBlock {
            Record -name $StageLabel {
                foreach ($p in $Stage.parameters.keys) {if ($Stage.parameters[$p] -notmatch "\r|\n") {row ($p +": " + $Stage.parameters[$p])}
                                                        else {row ($p +": " + $Stage.parameters[$p] -replace '[\r\n]+\s*',('<br/>  ' + (' '*$p.length)) )}
                }
            }
        }
        edge $Parent -to $StageLabel
        return
    }
    elseif ($Stage.stage)    {$StageLabel = "Stage: " + $Stage.stage}
    else                     {$StageLabel = "Stage_" + (++ $script:dupNames['stage'])}
    #Either the stage is has a set of jobs or it is a template (don't deal with anything else yet)
    if     ($Stage.jobs) {
        subgraph -Attributes @{rankDir='LR'; label=$StageLabel} -ScriptBlock {
            foreach ($j in $Stage.jobs) {
                plot_job -Job $j
            }
        }
        if     ($Stage.jobs[0].job)        {edge $Parent -to "Job: $($Stage.jobs[0].job)"}
        elseif ($Stage.jobs[0].deployment) {edge $Parent -to  $Stage.jobs[0].deployment}
    }
}

function plot_pipeline {
    param (
        $YAMLPath,
        [Parameter(ParameterSetName='raw',Mandatory=$true)]
        [switch]$Raw,
        [Parameter(ParameterSetName='File')]
        $DestinationPath,
        $PipelineName,
        $DontShow
    )
    $y = Get-Content $YAMLPath -Raw |  ConvertFrom-Yaml
    if (-not $PipelineName)    {$PipelineName = (Split-Path -Path $YAMLPath -Leaf) -replace '\.yml',''}
    $script:previous = $null
    $script:dupNames = @{}
    $graph = Graph -ScriptBlock {
        if ($y.parameters) {
            Record -name $PipelineName {
                foreach ($p in $y.parameters) {row $p.name}
            }
        }
        else {node -Name $PipelineName -Shape box }
        if ($y.stages) {
            foreach ($stage in $y.stages) {plot_stage -Parent $PipelineName -Stage $stage}
        }
        elseif ($y.jobs) {
            foreach ($job in $y.jobs) {
                $script:previous = $PipelineName
                plot_job -Job $job
            }
        }
        elseif ($y.steps) {
            $script:previous = $PipelineName
            foreach ($step in $y.steps) {
               plot_step -step $step
            }
        }

    }
    if ($raw) {return $graph}
    else {
        if (-not $PSBoundParameters.ContainsKey("DestinationPath")) {$DestinationPath = $YAMLPath -replace 'yml$','svg' }
        graph    | Export-PSGraph -OutputFormat svg -DestinationPath $DestinationPath -ShowGraph:(-not $DontShow)
    }
}