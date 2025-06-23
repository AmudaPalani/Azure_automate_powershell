# Connect to Azure and Microsoft Graph
Connect-AzAccount
Connect-MgGraph -Scopes "Device.ReadWrite.All"

Install-Module -Name Az.ConnectedMachine -AllowClobber -Force

# Get all Azure arc servers that are windows servers
$windowsServers = Get-AzConnectedMachine | Where-Object { $_.OsType -eq "Windows" }

# Loop through each server and update the device
foreach ($server in $windowsServers) {

    $serverId = $server.Id
    
    # Step 1: Enable Microsoft Defender Antivirus (base component first)
    $defenderAntivirus = Get-MgDeviceManagementWindowsDefender -DeviceId $serverId
    if ($defenderAntivirus) {
        $defenderAntivirus.IsEnabled = $true
        Update-MgDeviceManagementWindowsDefender -DeviceId $serverId -IsEnabled $defenderAntivirus.IsEnabled
        Write-Host "Enabled Microsoft Defender Antivirus on device: $($server.Name)."
    }
    else {
        Write-Host "Microsoft Defender Antivirus not found for server: $($server.Name)"
    }
    
    # Step 2: Enable Microsoft Defender for Endpoint (advanced protection)
    $defenderEndpoint = Get-MgDeviceManagementWindowsDefenderAdvancedThreatProtection -DeviceId $serverId
    if ($defenderEndpoint) {
        $defenderEndpoint.IsEnabled = $true
        Update-MgDeviceManagementWindowsDefenderAdvancedThreatProtection -DeviceId $serverId -IsEnabled $defenderEndpoint.IsEnabled
        Write-Host "Enabled Microsoft Defender for Endpoint on device: $($server.Name)."
    }
    else {
        Write-Host "Microsoft Defender for Endpoint not found for server: $($server.Name)"
    }
    
    # Step 3: Switch Microsoft Defender Antivirus (MDAV) from Passive Mode to Active Mode (final step)
    $device = Get-MgDevice -Filter "id eq '$serverId'"
    if ($device) {
        $device.DeviceManagementAppId = "Microsoft Defender Antivirus"
        $device.DeviceManagementAppVersion = "Active"
        Update-MgDevice -DeviceId $serverId -DeviceManagementAppId $device.DeviceManagementAppId -DeviceManagementAppVersion $device.DeviceManagementAppVersion
        Write-Host "Updated device: $($server.Name) to Active Mode."
    }
    else {
        Write-Host "Device not found for server: $($server.Name)"
    }

}