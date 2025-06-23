# Azure Automation PowerShell Scripts

This repository contains PowerShell scripts for automating Azure security configurations.

## Scripts

### windowsactive.ps1

**Purpose**: Forces Microsoft Defender Antivirus from passive mode to active mode on Azure Arc-enabled Windows servers.

#### What it does:
1. **Connects to Azure** and authenticates
2. **Filters servers** by tag `force_defender_av_from_passive_to_active:true`
3. **Detects 3rd-party antivirus** products on each server
4. **Conditionally activates Defender**:
   - If 3rd-party AV detected: Skips activation to avoid conflicts
   - If no 3rd-party AV: Forces Defender to active mode
5. **Provides status verification** of Defender components

#### Prerequisites:
- Azure PowerShell module (`Az.ConnectedMachine`)
- Proper Azure permissions for Arc-enabled machines
- Target servers must be Azure Arc-enabled Windows machines

#### Usage:

1. **Tag your servers** first:
   ```powershell
   # Tag servers that should have Defender forced to active mode
   Update-AzConnectedMachine -ResourceGroupName "MyRG" -Name "Server01" -Tag @{force_defender_av_from_passive_to_active="true"}
   ```

2. **Run the script**:
   ```powershell
   .\windowsactive.ps1
   ```

3. **Optional**: Uncomment and set your subscription ID if needed:
   ```powershell
   Set-AzContext -SubscriptionId "<your-subscription-id>"
   ```

#### Script Behavior:

**Safe Operation**: The script will NOT activate Defender if 3rd-party antivirus is detected, preventing conflicts.

**Output in Terminal**:
- ✅ Success/failure status for each server
- ⚠️ Warnings about 3rd-party AV detection
- Note: Detailed remote execution output is not displayed in the local terminal

**What Gets Activated**:
- Real-time protection (`Set-MpPreference -DisableRealtimeMonitoring $false`)
- Forces Defender from passive to active mode

#### Target Servers:
Only processes Azure Arc-enabled Windows servers with the tag:
- `force_defender_av_from_passive_to_active: true`

#### Security Considerations:
- Script safely checks for existing antivirus before making changes
- Prevents multiple AV conflicts by skipping activation when 3rd-party AV is present
- Uses Azure Arc's secure command execution channel

---

## Contributing

Please ensure all scripts include proper error handling and security considerations before committing.