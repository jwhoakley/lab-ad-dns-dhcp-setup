# Connect to new remote host running WS2019 Core and
# Install 'DNS', 'DHCP' and 'AD-Domain-Services' and all dependencies
#
# https://social.technet.microsoft.com/Forums/lync/en-US/ba61d5c7-f3f5-4280-91a4-0c2cfb5bd8fe/invokecommand-and-getwindowsfeatures?forum=winserverpowershell
#
$computername="10.16.51.25"
$credential = Get-Credential
$RolesAndFeatures = @('DNS','DHCP','AD-Domain-Services')

# Open PSSession
$rs = New-PSSession -ComputerName $computername -Credential $credential

# Check that a static IP address has been configured before installing DHCP Server
#

#Roles and Features section
foreach ( $RA in $RolesAndFeatures ) {
    $check = Invoke-Command -Session $rs -ScriptBlock { Get-WindowsFeature -name $using:RA }
    Write-Host ($check | Format-Table | Out-String)

    if ($check.InstallState -notmatch 'Installed') {
        $install = Invoke-Command -Session $rs -ScriptBlock { Install-WindowsFeature -Name $using:RA }
        Write-host ($install | Format-Table | Out-String)
    }
}

# reboot host
#

# Close PSSession
Remove-PSSession $rs