[CmdletBinding()] 
Param(  
[Parameter(Mandatory=$True)] 
[string]$target,
[string]$AdminLoginUserName, 
[string]$AdminPassword
) 


$global:target = $target.Trim()
$global:AdminLoginUserName = $AdminLoginUserName.Trim()
$global:AdminPassword = $AdminPassword.Trim()

# Trap for an exception during the script
trap [Exception]
{
    if($PSItem.ToString() -eq "ExecutionFailure")
	{
		exit 1
	}
	else
	{
		write-error $("Trapped: $_")
		write-host "Aborting Operation."
		exit
	}
}


function Validate-AdminLoginUserName{
    if((($global:AdminLoginUserName) -eq $null) -or (($global:AdminLoginUserName) -eq ""))
    {
        $global:UserNameFlag = 1
    }
    else {
        if($global:AdminLoginUserName -Notmatch $AdminLoginUserNameRegex) {
            Write-Host "Enter valid Admin Login User Name"
            $global:flag = 1
            exit 
        } 
        else {
            $SecurePassword = ConvertTo-SecureString -AsPlainText -Force -String "$global:AdminPassword"
            $global:Creds = New-Object System.Management.Automation.PSCredential (($global:AdminLoginUserName), $SecurePassword)
        }
    }
}

function Install-SCCMupdates
{

$system=$global:target

$TargetedUpdates= Get-WmiObject -ComputerName $system -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate

$pendingpatches=($TargetedUpdates |Where-Object {$TargetedUpdates.EvaluationState -ne 8} |Measure-Object).count

$approvedUpdates= ($TargetedUpdates |Measure-Object).count


if ($pendingpatches -gt 0) 
{
  try {
	$MissingUpdatesReformatted = @($TargetedUpdates | ForEach-Object {if($_.ComplianceState -eq 0){[WMI]$_.__PATH}}) 
	$InstallReturn = Invoke-WmiMethod -ComputerName $system -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$MissingUpdatesReformatted) -Namespace root\ccm\clientsdk 
	"$system,Targeted Patches :$approvedUpdates,Pending patches:$pendingpatches,Reboot Pending patches :$rebootpending,initiated $pendingpatches patches for install" 
	  }
	catch {"$System, pending patches - $pendingpatches but unable to install them ,please check Further"  }
}
else {"$system,Targeted Patches :$approvedUpdates,Pending patches:$pendingpatches,Reboot Pending patches :$rebootpending,Compliant"  }


}

Validate-AdminLoginUserName
Install-SCCMupdates

