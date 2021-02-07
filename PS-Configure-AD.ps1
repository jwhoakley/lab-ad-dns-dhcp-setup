# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#
# https://cloudblogs.microsoft.com/industry-blog/en-gb/technetuk/2016/06/08/setting-up-active-directory-via-powershell
# https://www.thegeekstuff.com/2014/12/install-windows-ad/
#

# Fixed variables
$RolesAndFeatures = @('DNS','AD-Domain-Services')

# Get variables from file
# install-conf.txt file format:
#   computername = <ip address>
#   domain = <string>
#   netbiosname = <string>
$var = get-content .\config-conf.txt | Out-String | ConvertFrom-StringData
$computername = $var.computername
$domain = $var.domain
$netbiosname = $var.netbiosname
$safemodepswd = $var.safemodesecpswd | ConvertTo-SecureString -Key (1..16)

# User input variables
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
        -SafeModeAdministratorPassword $safemodepswd `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainMode "WinThreshold" `
        -DomainName $using:domain `
        -DomainNetbiosName $using:netbiosname `
        -ForestMode "WinThreshold" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$false `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
}
write-host ($configure | Format-Table | Out-String)

# Configure reverse lookup zone

# reboot host
#  - is this needed?

# Close PSSession
Remove-PSSession $rs