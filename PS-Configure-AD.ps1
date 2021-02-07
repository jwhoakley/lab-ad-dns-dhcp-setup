# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#
$computername="10.16.51.25"
$credential = Get-Credential
$RolesAndFeatures = @('DNS','AD-Domain-Services')

# Open PSSession
$rs = New-PSSession -ComputerName $computername -Credential $credential

# Check that DNS and ADDS are installed 
foreach ( $RA in $RolesAndFeatures ) {
    $check = Invoke-Command -Session $rs -ScriptBlock { Get-WindowsFeature -name $using:RA }
    if ($check.InstallState -notmatch 'Installed') {
        Write-host ($install | Format-Table | Out-String)
        exit
    }
}

# Configure AD
# Import-Module ADDSDeployment

VM: 10.16.51.25
default password for Administrator


New-NetFirewallRule -DisplayName "Allow inbound ICMPv4" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress <localsubnet> -Action Allow

New-NetFirewallRule -DisplayName "Allow inbound ICMPv6" -Direction Inbound -Protocol ICMPv6 -IcmpType 8 -RemoteAddress 10.16.48.0/22 -Action Allow

Set-NetFirewallRule -Name WINRM-HTTP-In-TCP-PUBLIC -RemoteAddress Any

get-netfirewallrule -enabled true -direction inbound | more



https://www.thegeekstuff.com/2014/12/install-windows-ad/

Install-windowsfeature AD-domain-services

Import-Module ADDSDeployment

Install-ADDSForest
 -CreateDnsDelegation:$false `
 -DatabasePath "C:\Windows\NTDS" `
 -DomainMode "WinThreshold" `
 -DomainName "citrixlab.local" `
 -DomainNetbiosName "CITRIXLAB" `
 -ForestMode "WinThreshold" `
 -InstallDns:$true `
 -LogPath "C:\Windows\NTDS" `
 -NoRebootOnCompletion:$false `
 -SysvolPath "C:\Windows\SYSVOL" `
 -Force:$true


# Configure reverse lookup zone

# reboot host
#

# Close PSSession
Remove-PSSession $rs