# Connect to Azure
Connect-AzAccount

# Select your subscription if needed
# Set-AzContext -SubscriptionId "<your-subscription-id>"

# Get all Arc-enabled Windows servers with the specific tag
$windowsArcMachines = Get-AzConnectedMachine | Where-Object {
    $_.OsType -eq 'Windows' -and 
    $_.Tags.force_defender_av_from_passive_to_active -eq 'true'
}

# Script to force Microsoft Defender AV to active mode
$defenderActivationScript = @"
# Check for third-party antivirus products
Write-Output "Checking for existing antivirus products..."
`$avProducts = Get-WmiObject -Namespace 'root\SecurityCenter2' -Class 'AntiVirusProduct' -ErrorAction SilentlyContinue
`$thirdPartyAV = `$avProducts | Where-Object { `$_.displayName -notlike '*Windows Defender*' -and `$_.displayName -notlike '*Microsoft Defender*' }

if (`$thirdPartyAV) {
    Write-Output "⚠️ Third-party AV detected: `$(`$thirdPartyAV.displayName -join ', ')"
    Write-Output "Skipping Microsoft Defender activation to avoid conflicts"
} else {
    Write-Output "No third-party AV detected"
    Write-Output "Forcing Microsoft Defender to active mode..."
    
    # Force Defender to active mode
    Set-MpPreference -DisableRealtimeMonitoring `$false
    
    Write-Output "✅ Microsoft Defender forced to active mode"
}

# Get current Defender status for verification
`$mpStatus = Get-MpComputerStatus
Write-Output "Current Defender Status:"
Write-Output "  Real-time Protection: `$(`$mpStatus.RealTimeProtectionEnabled)"
Write-Output "  AntiSpyware: `$(`$mpStatus.AntiSpywareEnabled)"
Write-Output "  Behavior Monitor: `$(`$mpStatus.BehaviorMonitorEnabled)"
"@

# Loop through each Arc-enabled Windows machine and invoke the script
foreach ($machine in $windowsArcMachines) {
    Write-Host "Applying Defender AV settings on $($machine.Name)..."

    try {
        Invoke-AzConnectedMachineCommand `
            -ResourceGroupName $machine.ResourceGroupName `
            -MachineName $machine.Name `
            -CommandId 'RunPowerShellScript' `
            -ScriptString $defenderActivationScript

        Write-Host "✅ Successfully invoked on $($machine.Name)"
    }
    catch {
        Write-Warning "❌ Failed to invoke on $($machine.Name): $_"
    }
}