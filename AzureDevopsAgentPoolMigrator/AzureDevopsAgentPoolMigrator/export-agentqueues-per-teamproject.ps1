# This script will export the agent queue mapping, required for the migrator and it will generate a powershell script to call the migrator
# This script needs to run on the on-prem environment. The generated script needs to run on the cloud environment
# The OldAgentPoolMappings directory should be copied into the bin-directory of the AzureDevOpsAgentPoolMigrator

$coll = "http://tfsserver:8080/tfs/DefaultCollection"
$pat = Get-Content -Path ".\pat.txt"
$header = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }
$outputpath = "C:\Tools\AzureDevOpsAgentPoolMigrator\OldAgentPoolMappings"
$callscriptpath = "C:\Temp\fix-release-queues-pools.ps1"
$pathtoagentpoolmigratorexe = "C:\Tools\AzureDevOpsAgentPoolMigrator\AzureDevopsAgentPoolMigrator.exe"

class AgentQueue {
    [string]$Name
    [int]$Id
}

function Get-JsonOutput($uri, [bool]$usevalueproperty = $true)
{
    $output = (invoke-webrequest -Uri $uri -Method GET -ContentType "application/json" -Headers $header) | ConvertFrom-Json
    if ($usevalueproperty)
    {
        return $output.value
    }
    else 
    {
        return $output
    }
}

function Get-TeamProjects ()
{
    return Get-JsonOutput -uri "$coll/_apis/projects"
}

function Get-AgentQueues($teamproject)
{
    $queues = Get-JsonOutput -uri "$coll/$teamproject/_apis/distributedtask/queues"
    $agentqueuesarray = New-Object System.Collections.ArrayList
    foreach ($queue in $queues)
    {
        $agentqueueobject = New-Object AgentQueue
        $agentqueueobject.Id = $queue.id
        $agentqueueobject.Name = $queue.name
        $agentqueuesarray.Add($agentqueueobject) | Out-Null
    }
    return $agentqueuesarray
}

$callscript = ""
$teamprojects = Get-TeamProjects
foreach ($teamproject in $teamprojects)
{
    Get-AgentQueues -teamproject $teamproject.name | ConvertTo-Json | Out-File -FilePath "$($outputpath)\$($teamproject.name)_old_agent_pools.json"
    $callscript += ". $pathtoagentpoolmigratorexe `"$($teamproject.name)`"`n"
}
$callscript | Out-File -FilePath $callscriptpath
