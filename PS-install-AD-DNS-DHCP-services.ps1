# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#

# Get variables from file
# install-conf.txt file format:
#   computername = <ip address>
#   features = <comma separated list>
$var = get-content .\install-conf.txt | Out-String | ConvertFrom-StringData
$computername = $var.computername
$hostname = $var.hostname
$RolesAndFeatures = 'DNS', 'DHCP', 'AD-Domain-Services'
# User input for access credentials
$credential = Get-Credential

# Open PSSession
$rs = New-PSSession -ComputerName $computername -Credential $credential

# Check that a static IP address has been configured before installing DHCP Server
#
$interface = Invoke-Command -Session $rs -ScriptBlock { (Get-NetAdapter | Where-Object { $_.Status -eq "up" }) | Get-NetIPInterface -AddressFamily IPv4 }
If ($interface.Dhcp -eq "Enabled") {
    write-host "`nDHCP is enabled on this system. This should be static before installing DHCP: "
    Write-Host ($interface | Format-Table | Out-String)
    $RolesAndFeatures = 'DNS', 'AD-Domain-Services'
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


# Set Target node hostname
Rename-Computer -NewName $hostname

# reboot host
Restart-Computer -ComputerName $computername -Credential $credential -Force
