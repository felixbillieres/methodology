# Énumération Post-Compromission

## Énumération Manuelle avec PowerView

### Installation et configuration
```powershell
# Importer PowerView
Import-Module .\PowerView.ps1

# Contourner la politique d'exécution si nécessaire
powershell -ep bypass
```
### Énumération du domaine
```powershell
# Informations sur le domaine
Get-Domain
Get-DomainController | select Name,IPAddress,Domain,Forest

# Politique de mot de passe
Get-DomainPolicy | select -ExpandProperty SystemAccess
```
### Énumération des utilisateurs et groupes
```powershell
# Utilisateurs
Get-DomainUser | select samaccountname,description,pwdlastset,lastlogon
Get-DomainUser -Properties * | Where-Object {$_.Description -ne ""} | select name,description

# Groupes privilégiés
Get-DomainGroupMember -Identity "Domain Admins" | select MemberName
Get-DomainGroupMember -Identity "Enterprise Admins" | select MemberName
Get-DomainGroupMember -Identity "Administrators" | select MemberName
```
### Droits d'administration locale
```powershell
# Trouver où l'utilisateur courant a des droits d'admin local
Find-LocalAdminAccess

# Rechercher les sessions utilisateur actives
Find-DomainUserLocation | select UserName,SessionFromName
```
## Énumération des ACLs
### Recherche d'ACLs intéressantes
```powershell
# Convertir nom d'utilisateur en SID
$sid = Convert-NameToSid "username"

# Rechercher tous les droits pour cet utilisateur
Get-DomainObjectACL -Identity * | ? {$_.SecurityIdentifier -eq $sid}

# Avec résolution des GUIDs (plus lisible)
Get-DomainObjectACL -ResolveGUIDs -Identity * | ? {$_.SecurityIdentifier -eq $sid}
```
### Identifier les droits spécifiques
```powershell
# Rechercher les droits DCSync
Get-ObjectAcl "DC=inlanefreight,DC=local" -ResolveGUIDs | ? { ($_.ObjectAceType -match 'Replication-Get') }

# Rechercher ForceChangePassword
$guid = "00299570-246d-11d0-a768-00aa006e0529"
Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).ConfigurationNamingContext)" -Filter {objectClass -like 'ControlAccessRight'} -Properties * | Select Name,DisplayName,DistinguishedName,rightsGuid| ?{$_.rightsGuid -eq $guid}
```
## Collecte de données avec BloodHound
### Collecte avec SharpHound
```powershell
# Depuis PowerShell
Import-Module .\SharpHound.ps1
Invoke-BloodHound -CollectionMethod All -OutputDirectory C:\Users\username\Desktop\ -OutputPrefix "audit"

# Avec l'exécutable
.\SharpHound.exe -c All --ZipFileName audit.zip
```
### Collecte depuis Linux
```bash
# Avec bloodhound-python
bloodhound-python -d inlanefreight.local -u username -p password -c All -ns 172.16.5.5
```
### Analyse avec BloodHound
```bash
# Démarrer Neo4j
sudo neo4j start
# Démarrer BloodHound
bloodhound
```

Requêtes intéressantes à exécuter dans BloodHound:
- Trouver tous les plus courts chemins vers les Domain Admins
- Trouver les comptes kerberoastables
- Trouver les hôtes où Domain Users peut RDP
- Trouver les utilisateurs avec DCSync rights

## Recherche de Configurations Dangereuses

### Utilisateurs vulnérables aux attaques d'authentification

```powershell
# Utilisateurs Kerberoastables (avec SPN)
Get-DomainUser -SPN | select samaccountname,serviceprincipalname

# Utilisateurs AS-REP Roastables
Get-DomainUser -PreauthNotRequired | select samaccountname
```

### Identification de délégations dangereuses

```powershell
# Délégation contrainte
Get-DomainComputer -TrustedToAuth | select name,msds-allowedtodelegateto

# Délégation non contrainte
Get-DomainComputer -Unconstrained | select name
```

### Recherche de fichiers sensibles

```powershell
# Recherche de mots de passe dans les fichiers
findstr /si password *.txt *.ini *.config *.xml

# Chercher dans les fichiers de scripts
Get-ChildItem -Path C:\Users\* -Include *.ps1,*.bat,*.cmd -Recurse -ErrorAction SilentlyContinue | Select-String -Pattern "password"
```

## Utilisation d'outils supplémentaires

### Snaffler (pour trouver des credentials)

```powershell
# Lancer Snaffler
.\Snaffler.exe -s -d inlanefreight.local -o snaffler.log -v data
```

### Enumération des défenses de sécurité

```powershell
# Vérifier l'état de Windows Defender
Get-MpComputerStatus | Select RealTimeProtectionEnabled,AntivirusEnabled

# Vérifier les pare-feu
Get-NetFirewallProfile | Select Name,Enabled
```

## Points Clés à Documenter

- Utilisateurs et groupes privilégiés
- ACLs potentiellement exploitables
- Chemins d'attaque identifiés par BloodHound
- Comptes vulnérables aux attaques d'authentification
- Configurations de délégation dangereuses
- Traces de mots de passe et credentials