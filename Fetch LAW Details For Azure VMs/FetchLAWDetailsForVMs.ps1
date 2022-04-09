

#Connect-AzAccount

#Import-Module -Name "Az"

$subscriptions = Get-AzSubscription | Where-Object {$_.Name -notlike "Access to Azure Active*"}
$workspace_array = @()
$extension_details = @()

foreach($sub in $subscriptions)
{
  Select-AzSubscription -SubscriptionName $sub
  $workspace_array += Get-AzOperationalInsightsWorkspace

}

foreach($sub in $subscriptions)
{
  Select-AzSubscription -SubscriptionName $sub

 
  $VMs = Get-AzVM

  foreach($vm in $VMs)
  {
   $lin_extension_name = "OMSAgentForLinux"
   $win_extension_name = "MicrosoftMonitoringAgent"
   $get_extension = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name | Where-Object { $_.Name -eq $win_extension_name -or $_.Name -eq $lin_extension_name } -ErrorAction Continue
   $extension_temp = New-Object psobject 
   $extension_temp | Add-Member -MemberType NoteProperty -Name "SubscriptionName" -Value $sub.Name
   $extension_temp | Add-Member -MemberType NoteProperty -Name "VMName" -Value $vm.Name
   $extension_temp | Add-Member -MemberType NoteProperty -Name "ResourceGroup" -Value $vm.ResourceGroupName
   if($get_extension -ne $null)
   {
   $workspace_id = ( $get_extension.PublicSettings | ConvertFrom-Json).workspaceId
   
   foreach($w in $workspace_array)
   {
    if($w.CustomerId.Guid -eq $workspace_id)
    { 
     $workspaceName = $w.Name
     $workspaceRG = $w.ResourceGroupName
     $workspaceResourceId = $w.ResourceId
     break
    }
    else
    {
     $workspaceName = "Doesn't exist"
     $workspaceRG = ""
     $workspaceResourceId = ""
    }
   }
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceId" -Value $workspace_id
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceName" -Value $workspaceName
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceResourceGroup" -Value $workspaceRG
   $extension_temp | Add-Member -MemberType NoteProperty -Name "workspaceResourceId" -Value $workspaceResourceId
   
   }
   else {
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceId" -Value "Not Found"
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceName" -Value ""
   $extension_temp | Add-Member -MemberType NoteProperty -Name "WorkspaceResourceGroup" -Value ""
   $extension_temp | Add-Member -MemberType NoteProperty -Name "workspaceResourceId" -Value ""
   }

   $extension_details += $extension_temp
  }
}
$extension_details | Export-Csv -Path "C:\Users\SkumarRamalin\Desktop\OneFamily\Scripts\workspace10.csv" -NoTypeInformation -NoClobber
