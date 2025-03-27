# Reconnaissance et Découverte Initiale

## Informations Externes

### Recherche de Domaines et Sous-domaines

```bash
# Recherche WHOIS et enregistrements DNS
whois inlanefreight.com
dig inlanefreight.com ANY
dig -x [IP_ADDRESS]  # Recherche DNS inverse

# Outils en ligne
# - domaintools.com
# - viewdns.info
# - Hurricane Electric BGP Toolkit (bgp.he.net)
```

### Recherche d'Informations sur Internet

- LinkedIn pour identifier employés et structure organisationnelle
- Sites corporate pour données de contact et noms d'utilisateurs
- GitHub pour fuites de données et conventions de nommage

### Découverte d'ASN et d'Espace d'Adressage

```bash
# Identifier les blocs d'adressage associés à l'organisation
curl -s https://bgp.he.net/search?search=[COMPANY_NAME] | grep -oE "AS[0-9]+"
whois -h whois.radb.net -- '-i origin [ASN]' | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}"
```

## Découverte d'Hôtes et Services

### Balayage de Réseau

```bash
# Découverte d'hôtes actifs
fping -asgq [SUBNET]/[MASK]
nmap -sn [SUBNET]/[MASK]

# Scan de ports et services
nmap -sV -p- --min-rate 1000 [TARGET_IP]
```

### Identification des Contrôleurs de Domaine

```bash
# Découverte LDAP et DNS
nmap -p 389,636,3268,3269,53,88,464 [SUBNET]/[MASK]

# Requête DNS pour localiser DCs
host -t SRV _ldap._tcp.inlanefreight.local
```

## Services Exposés

### Énumération SMB

```bash
nmap --script smb-protocols,smb-security-mode,smb-enum-shares [TARGET_IP]
```

### Services d'Authentification

```bash
# Vérifier les services Kerberos et LDAP
nmap -p 88,389,636,3268,3269 --script=ldap-search,ldap-rootdse [TARGET_IP]
```

### Détection des Services Web

```bash
# Scan des portails web internes (OWA, VPN, intranet)
nmap -p 80,443,8080,8443 --open [SUBNET]/[MASK]
```

## Informations sur le Domaine

### Identifier la Structure du Domaine

```bash
# Utilisation de rpcclient pour sessions NULL
rpcclient -U "" -N [DC_IP]
rpcclient $> querydominfo
rpcclient $> enumdomusers

# Avec identifiants valides
rpcclient -U "username%password" [DC_IP]
```

### Vérifier la Politique de Mot de Passe

```bash
# Sans identifiants (session NULL)
enum4linux -P [DC_IP]

# Avec identifiants
crackmapexec smb [DC_IP] -u username -p password --pass-pol
```

## Points Clés à Noter

- Noms de domaine complets (FQDN) des contrôleurs de domaine
- Conventions de nommage des utilisateurs/ordinateurs
- Ports ouverts et services disponibles 
- Présence de serveurs d'authentification externes (ADFS, etc.)
- Versions des systèmes d'exploitation