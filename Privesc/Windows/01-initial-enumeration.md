## Initial Enumeration

### System Information
```powershell
systeminfo
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" /C:"System Type"
wmic qfe list
[environment]::OSVersion.Version
Get-HotFix | ft -AutoSize
wmic product get name,version
```

### User & Group Enumeration
```powershell
whoami
whoami /priv
whoami /groups
net user
net user [username]
net localgroup
net localgroup administrators
Get-LocalUser
Get-LocalGroup
Get-LocalGroupMember administrators
```

### Network Enumeration
```powershell
ipconfig /all
arp -a
route print
netstat -ano
Get-NetTCPConnection
Get-NetIPConfiguration | ft InterfaceAlias,InterfaceDescription,IPv4Address
Get-DnsClientServerAddress -AddressFamily IPv4 | ft
```

### Process Enumeration
```powershell
tasklist /svc
Get-Process
Get-CimInstance -ClassName win32_service | Select Name,State,PathName | Where-Object {$_.State -like 'Running'}
wmic service list brief
```

### AppLocker & AV Enumeration
```powershell
Get-MpComputerStatus
Get-AppLockerPolicy -Effective | select -ExpandProperty RuleCollections
Get-AppLockerPolicy -Local | Test-AppLockerPolicy -path C:\Windows\System32\cmd.exe -User Everyone
sc query windefend
netsh advfirewall show currentprofile
```
## Techniques d'élévation de privilèges Windows dans des Box
### Analyse des services et ports ouverts
Exemple (Legacy):
```bash
# Utiliser Nmap avec des scripts de vulnérabilité
nmap -p 445 --script vuln <IP>

# Identifier les services vulnérables
nmap -sV -p <PORT> <IP>
```
### Énumération des partages SMB
Exemple (Nest):
```bash
# Énumération des partages avec smbmap
smbmap -H <IP> -u null

# Connexion anonyme avec smbclient
smbclient -N //<IP>/<SHARE>

# Téléchargement récursif de fichiers
smb: \> recurse ON
smb: \> prompt OFF
smb: \> mget *
```
