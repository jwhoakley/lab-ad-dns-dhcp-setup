# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#
# https://social.technet.microsoft.com/Forums/lync/en-US/ba61d5c7-f3f5-4280-91a4-0c2cfb5bd8fe/invokecommand-and-getwindowsfeatures?forum=winserverpowershell
#
# NOTE: If the remote PS host is outside of the target host's subnet the default FW policy will block WINRM access
#       It will be necessary to run a local PS command to relax the firewall rule a little: Set-NetFirewallRule -Name WINRM-HTTP-In-TCP-PUBLIC -RemoteAddress Any

# Fixed variables
$RolesAndFeatures = @('DNS','DHCP','AD-Domain-Services')

# Get variables from file
# install-conf.txt file format:
#   computername = <ip address>
$var = get-content .\install-conf.txt | Out-String | ConvertFrom-StringData
$computername = $var.computername

# User input variables
$credential = Get-Credential

# Open PSSession
$rs = New-PSSession -ComputerName $computername -Credential $credential

# Check that a static IP address has been configured before installing DHCP Server
#
$interface = Invoke-Command -Session $rs -ScriptBlock { (Get-NetAdapter | Where-Object {$_.Status -eq "up"}) | Get-NetIPInterface -AddressFamily IPv4 }
If ($interface.Dhcp -eq "Enabled") {
    write-host "`nDHCP is enabled on this system. This should be static before installing DHCP: "
    Write-Host ($interface | Format-Table | Out-String)
    exit
}

#Roles and Features section
foreach ( $feature in $RolesAndFeatures ) {
    # Check status of role/feature
    $check = Invoke-Command -Session $rs -ScriptBlock { Get-WindowsFeature -name $using:feature }
    Write-Host ($check | Format-Table | Out-String)

    # If role/feature is not installed, then install
    if ($check.InstallState -notmatch 'Installed') {
        $install = Invoke-Command -Session $rs -ScriptBlock { Install-WindowsFeature -Name $using:feature }
        Write-host ($install | Format-Table | Out-String)
    }
}

# reboot host
#
Restart-Computer -ComputerName $computername -Credential $credential -Force

# Close PSSession - is this needed??
Remove-PSSession $rs