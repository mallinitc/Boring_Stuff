#This script reads all VMs names from TXT file
#Then checks if there is a snapshot exists with name <vmname>-patchmgmt-<month>-<year>, if yes it deletes it & then create a new one with same name

#Read VMnames
$Vms = gc D:\vms.txt

#Connect Azure portal
If(Connect-AzAccount -Subscription <subscriptionid> -Tenant <tenantid>)
{

$Now = Get-Date
$AllVms = Get-AzVM
$AllSnaps = Get-AzSnapshot

foreach($vmname in $vms)
{
    $vmname = $vmname.Trim()
    $Vm = $AllVms|?{$_.Name -like $vmname}
    $Snapname = $vmname + '-patchmgmt-' +(Get-Culture).DateTimeFormat.GetAbbreviatedMonthName($Now.Month) + $Now.Year
    If($AllSnaps|?{$_.Name -like $Snapname})
    {
        #Deleting
        $AllSnaps|?{$_.Name -like $Snapname}|Remove-AzSnapshot -Confirm:$false -Force
        Start-Sleep 7
    }
    #Creating Snapshot
    #Snapshot
    $Diskname = $Vm.StorageProfile.OsDisk.Name
    $VmDisk = Get-AzDisk -Name $Diskname -ResourceGroupName $Vm.ResourceGroupName
    $SnapshotConfig = New-AzSnapshotConfig -SourceUri $VmDisk.Id -CreateOption Copy -Location $VmDisk.Location
    New-AzSnapshot -Snapshot $SnapshotConfig -SnapshotName $Snapname -ResourceGroupName $Vm.ResourceGroupName -AsJob 
}

while (Get-Job -State "Running")
{
    Write-Host "Jobs are still running..."
    Start-Sleep -s 5
}
Get-Job -State Completed|Remove-Job
Get-Job -State Failed|Remove-Job
}
else { Write-Host "Incorrect login" -ForegroundColor Yellow }