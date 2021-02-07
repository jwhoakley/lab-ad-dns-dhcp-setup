$Features = @{}
$Features += @{ $RA = 'Not Installed' }
write-host -ForegroundColor Red ($Features | Format-Table | Out-String)


#Enter-PSSession -ComputerName $computername -Credential $credential
#Exit-PSSession


# Tests for open PSSession
# Invoke-Command -Session $rs -ScriptBlock { [System.Net.Dns]::GetHostName() }

# Read whether the desired roles/features are already enabled
#    import-module ServerManager
#    Install-WindowsFeature -Name <feature_name> -computerName <computer_name> -Restart
write-host "Opening session to remote host $computername"

