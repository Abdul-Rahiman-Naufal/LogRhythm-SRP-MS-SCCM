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

function Get-SCCMupdates{
    $i = 1
  

    $Updates = Get-WmiObject -ComputerName $global:target -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -Credential $global:Creds | Where-Object { $_.ComplianceState -eq "0" } | Select  Name, URL
    if(!($Updates)){
        Write-Host "No Updates are available"
        Exit
    }else{

        $UpdatesCount = (Get-WmiObject -ComputerName $global:target -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -Credential $global:Creds).count
                        
        Write-Host "Following"$UpdatesCount "updates are available:"
        Write-Host " "
        foreach($Update in $Updates){
            $Title = $Update.Name
            Write-Host "$i. $Title"
            $i = $i +1            
        }
    }
}

Validate-AdminLoginUserName
Get-SCCMupdates