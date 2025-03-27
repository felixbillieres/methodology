# Énumération du Domaine

## Énumération des Utilisateurs

### Utilisation de Kerbrute (méthode discrète)

```bash
# Téléchargement et compilation
git clone https://github.com/ropnop/kerbrute.git
cd kerbrute && make all

# Énumération des utilisateurs par bruteforce
./kerbrute_linux_amd64 userenum -d INLANEFREIGHT.LOCAL --dc 172.16.5.5 /path/to/userlist.txt -o valid_users.txt
```

### Énumération avec Credentials Valides

```bash
# Avec CrackMapExec
crackmapexec smb 172.16.5.5 -u username -p password --users

# Avec PowerView (depuis Windows)
Get-DomainUser | select samaccountname,description,memberof
Get-DomainUser -Properties * | Where-Object {$_.Description -like "*pass*"} | select name,description
```

## Énumération des Groupes

```bash
# Avec CrackMapExec
crackmapexec smb 172.16.5.5 -u username -p password --groups

# Avec PowerView
Get-DomainGroup | select samaccountname,description,memberof,member
Get-DomainGroupMember -Identity "Domain Admins" | select MemberName
```

## Énumération des Ordinateurs

```bash
# Avec CrackMapExec
crackmapexec smb 172.16.5.5 -u username -p password --computers

# Avec PowerView
Get-DomainComputer | select name,operatingsystem,dnshostname
Get-DomainComputer -Properties * | Where-Object {$_.operatingsystem -like "*Server*"} | select name,operatingsystem
```

## Énumération des Contrôleurs de Domaine

```bash
# Avec PowerView
Get-DomainController | select Name,IPAddress,Domain,Forest,OSVersion,Roles

# Avec LDAP
ldapsearch -x -h [DC_IP] -D "username@domain.local" -w "password" -b "DC=domain,DC=local" "(userAccountControl:1.2.840.113556.1.4.803:=8192)"
```
## Énumération des Politiques de Mots de Passe

```bash
# Avec PowerView
Get-DomainPolicy | select -ExpandProperty SystemAccess

# Avec CrackMapExec
crackmapexec smb 172.16.5.5 -u username -p password --pass-pol
```

## Énumération des Utilisateurs Connectés

```bash
# Recherche d'utilisateurs connectés sur les postes
crackmapexec smb [SUBNET]/[MASK] -u username -p password --loggedon-users

# Avec PowerView 
Find-DomainUserLocation | select UserName,SessionFromName
```

## Identifier les Serveurs Critiques

```bash
# Recherche d'ADCS (Certificate Services)
crackmapexec ldap [DC_IP] -u username -p password -M adcs

# Recherche d'Exchange
Get-DomainComputer -Properties * | Where-Object {$_.serviceprincipalname -like "*Exchange*"} | select name,dnshostname
```

## Configurations Sensibles

### Énumération des Partages SMB

```bash
# Trouver des partages intéressants
crackmapexec smb [SUBNET]/[MASK] -u username -p password --shares
smbmap -u username -p password -d domain -H [TARGET_IP]

# Recherche de fichiers sensibles
findstr /SI /M "password" \\server\share\*.txt *.xml *.ini *.config
```

### Détection de Configurations Dangereuses

```bash
# Recherche de comptes avec UF_DONT_REQUIRE_PREAUTH (AS-REP Roasting)
Get-DomainUser -PreauthNotRequired | select samaccountname,userprincipalname

# Recherche d'utilisateurs avec SPN (Kerberoasting)
Get-DomainUser -SPN | select samaccountname,serviceprincipalname
```

## Points Clés à Observer

- Utilisateurs avec descriptions contenant des mots de passe
- Comptes de service avec SPN
- Groupes sensibles et leurs membres
- Configurations dangereuses (authentification pré-requise désactivée)
- Serveurs critiques (ADCS, Exchange, SQL, etc.)