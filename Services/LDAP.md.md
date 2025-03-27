# LDAP (389/TCP)

Le Lightweight Directory Access Protocol (LDAP) est utilisé pour l'accès et la maintenance des services d'annuaire distribués.

## 🔍 Énumération

### Scan de base
```bash
# Scan LDAP avec Nmap
sudo nmap -n -sV -p 389,636,3268,3269 $IP

# Scripts Nmap spécifiques
nmap -n -sV --script="ldap* and not brute" -p 389,636 $IP
```

### Recherche anonyme
```bash
# Recherche anonyme basique
ldapsearch -x -H ldap://$IP -b "dc=domain,dc=com"

# Recherche avec base DN automatique
ldapsearch -x -H ldap://$IP -s base namingcontexts
```

### Énumération avec authentification
```bash
# Recherche avec identifiants
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com"

# Avec netexec
nxc ldap $IP -u 'username' -p 'password' --protocols ldap
```

## 🔨 Exploitation

### Énumération des utilisateurs et groupes
```bash
# Lister les utilisateurs
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com" "(&(objectClass=user)(objectCategory=person))"

# Lister les groupes
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com" "(objectClass=group)"

# Avec netexec
nxc ldap $IP -u 'username' -p 'password' --users
nxc ldap $IP -u 'username' -p 'password' --groups
```

### Recherche d'informations sensibles
```bash
# Recherche de mots de passe en clair ou attributs confidentiels
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com" | grep -i -E "pass|pwd|cred|secret"

# Recherche d'objets avec attributs spécifiques
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com" "(userPassword=*)"
```

### Modification d'attributs LDAP
```bash
# Création d'un fichier LDIF pour modification
cat > modify.ldif << EOF
dn: cn=user,dc=domain,dc=com
changetype: modify
replace: userPassword
userPassword: newpassword
EOF

# Application des modifications
ldapmodify -x -H ldap://$IP -D "cn=admin,dc=domain,dc=com" -w "password" -f modify.ldif
```

### Exploitation des vulnérabilités
```bash
# Test de CVE-2017-14773 (Open LDAP RCE)
nmap --script ldap-vuln-cve2017-14773 -p 389 $IP
```

## 🔐 Post-exploitation

### Extraction de données Active Directory
```bash
# BloodHound Ingestors
# SharpHound (Windows)
./SharpHound.exe -c all

# Python BloodHound (Linux)
pip install bloodhound
bloodhound-python -u username -p password -d domain.com -ns $IP -c all
```

### Exploitation des politiques de groupe (GPO)
```bash
# Énumération des GPO
nxc ldap $IP -u 'username' -p 'password' --gpos

# Recherche de scripts de connexion dans les GPO
ldapsearch -x -H ldap://$IP -D "cn=binduser,cn=users,dc=domain,dc=com" -w "password" -b "dc=domain,dc=com" "(objectCategory=groupPolicyContainer)"
```

### Recherche d'élévation de privilèges
```bash
# Recherche d'ACL dangereuses
findDelegation.py -dc-ip $IP domain.com/username:password
```

## ⚠️ Erreurs courantes & astuces
- Le LDAP non sécurisé (389) est distinct du LDAP sécurisé (636)
- Les recherches anonymes sont souvent désactivées sur les systèmes modernes
- Vérifiez les attributs accessibles avec et sans authentification
- Utilisez `-h` au lieu de `-H` pour les versions plus anciennes de ldapsearch
- La syntaxe des filtres LDAP peut varier selon l'implémentation