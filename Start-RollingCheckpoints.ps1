<#
.SYNOPSIS   
Script to create a checkpoint for all the VMs running on your Hypervisor and delete any checkpoints beyond the newest $KeptCheckpoints.    

.DESCRIPTION
Desigened to work as a scheduled task, this script creates checkpoints for all the virtual machines on your hyper-v server.
It also deletes any previously automatically generated checkpoints outside of the range you set, so you will get a rolling number of checkpoints. 
It should not delete any manually created checkpoints (unless you rename them "Auto Checkpoint*")

.NOTES   
Name: Start-RollingCheckpoints.ps1
Variant of: Start-CheckpointManagement.ps1
Author: Clyde Miller / ResNet @ Missouri State
Version: 1.1
DateCreated: 2015-07-21
DateUpdated: 2015-08-10

.LINK
http://thatclyde.com
http://resnet.missouristate.edu

.EXAMPLE   
.\Get-Start-RollingCheckpoints.ps1

Description:
Will create a checkpoint for each virtual machine running on your hyper-V server. 
If there are any checkpoints that the script created previously that are 29 days old or older, they will be deleted.

.NOTES:
This script only kind of addresses the 1599/1600 bug, where checkpoints will report that they were initially created centuries ago. If it's a checkpoint that purports to be that old, this script will ignore it.

#>
#define local variables
#All the VMs on the machine the script will work upon
$VMs = '*'
#The number of checkpoints that'll be saved
$KeptCheckpoints = 4
#The VM Names in a way that'll get passed into a function
$VMNames = Get-VM -Name $VMs | Select-Object name | foreach {$_.name}
    
#Finds Selected VMs (All by default), creates checkpoints for those VMs with the name "Auto Checkpoint" followed by the date (in a sortable format).
Get-VM $VMs | Checkpoint-VM -SnapshotName "Auto Checkpoint $((Get-Date -Format s))"

#Looking at each VM on the hypervisor
Foreach ($VM in $VMNames){
    #Finding each checkpoint/snapshot that was created with this script, and therefore named "Auto Checkpoint ..."
    $Checkpoints = Get-VMSnapshot -VMName $VM | Where-Object {$_.Name -match "Auto Checkpoint*"}
    #Determining if each VM has more checkpoints than the script says that it should need
    if ($Checkpoints.Count -gt $KeptCheckpoints)
    {
    #Starting a counter
    $i = 0
    #Determining how many checkpoints over the requested number it is, and making a loop that'll increment that many times
    $Keep = $Checkpoints.Count - $KeptCheckpoints
    While ($i -lt $Keep){
        #Determining the specific name of each checkpoint
        $Name = $Checkpoints[$i] | Select-Object name | foreach {$_.name}
        #Removing the checkpoints with that name - since the names are sortable, these will be the oldest checkpoints
        Get-VMSnapshot -VMName $VM | Where-Object Name -Match $Name | Remove-VMSnapshot
        #incrementing the counter
        $i++
        }
    } 
}
