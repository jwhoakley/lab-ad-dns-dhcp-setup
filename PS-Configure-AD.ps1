# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#
# https://cloudblogs.microsoft.com/industry-blog/en-gb/technetuk/2016/06/08/setting-up-active-directory-via-powershell
# https://www.thegeekstuff.com/2014/12/install-windows-ad/
#

# Fixed variables
$RolesAndFeatures = 'DNS', 'DHCP', 'AD-Domain-Services'

# Get variables from file
# install-conf.txt file format:
#   computername = <ip address>
#   domain = <string>
#   netbiosname = <string>
#   password = <string>
$var = get-content .\config-conf.txt | Out-String | ConvertFrom-StringData
$computername = $var.computername
$safemodepswd = (ConvertTo-SecureString -String $var.password -AsPlainText -Force)
$DomainName = $var.domain
$NetbiosName = $var.netbiosname
#Declare standard variables
$DatabasePath = "c:\windows\NTDS"
$DomainMode = "WinThreshold"
$ForestMode = "WinThreshold"
$LogPath = "c:\windows\NTDS"
$SysVolPath = "c:\windows\SYSVOL"
$featureLogPath = "c:\poshlog\featurelog.txt" 

# User input variables for login to remote Target host
$credential = Get-Credential

# Open PSSession
$rs = New-PSSession -ComputerName $computername -Credential $credential

# Check that DNS and ADDS are installed 
foreach ( $feature in $RolesAndFeatures ) {
    $check = Invoke-Command -Session $rs -ScriptBlock { Get-WindowsFeature -name $using:feature }
    if ($check.InstallState -notmatch 'Installed') {
        Write-Host "`n$feature is NOT currently installed. Run install script first."
        Write-host ($install | Format-Table | Out-String)
        exit
    }
}

# WARNING: A delegation for this DNS server cannot be created because the authoritative parent zone cannot be found or it does not run Windows DNS server. If you are integrating with an existing DNS infrastructure, 
# you should manually create a delegation to this DNS server in the parent zone to ensure reliable name resolution from outside the domain "mylab.local". Otherwise, no action is required.
#

# Configure AD
# command is not passing variables through to remote session
Invoke-Command -Session $rs -ScriptBlock { Import-Module ADDSDeployment }
$configure = Invoke-Command -Session $rs -ScriptBlock { 
    Install-ADDSForest `
        -SafeModeAdministratorPassword $using:safemodepswd `
        -CreateDnsDelegation:$false `
        -DatabasePath $using:DatabasePath `
        -DomainMode $using:DomainMode `
        -DomainName $using:DomainName `
        -DomainNetbiosName $using:NetbiosName `
        -ForestMode $using:ForestMode `
        -InstallDns:$true `
        -LogPath $using:LogPath `
        -NoRebootOnCompletion:$false `
        -SysvolPath $using:SysVolPath `
        -Force:$true
}
write-host ($configure | Format-Table | Out-String)

# Configure reverse lookup zone

# Close PSSession
Remove-PSSession $rs
