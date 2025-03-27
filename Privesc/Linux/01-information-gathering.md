### Basic Enumeration
```bash
whoami && id
hostname
ifconfig/ip a
sudo -l
cat /etc/os-release
uname -a
```
### Environment Enumeration
```bash
echo $PATH
env
cat /etc/shells
lsblk
find / -type f -name ".*" -exec ls -l {} \; 2>/dev/null | grep {username}
find / -type d -name ".*" -ls 2>/dev/null
ls -l /tmp /var/tmp /dev/shm
```
### Network & Services
```bash
ip a
cat /etc/hosts
lastlog
netstat -rn
ss -tuln
```
### History & Cron Jobs
```bash
history
find / -type f \( -name *_hist -o -name *_history \) -exec ls -l {} \; 2>/dev/null
ls -la /etc/cron.daily/
find /proc -name cmdline -exec cat {} \; 2>/dev/null | tr " " "\n"
```

### Configuration Files & Packages
```bash
find / -type f \( -name *.conf -o -name *.config \) -exec ls -l {} \; 2>/dev/null
apt list --installed
sudo -V
find / -type f -name "*.sh" 2>/dev/null | grep -v "src\|snap\|share"
ps aux | grep root
```

### Credential Hunting
```bash
find / ! -path "*/proc/*" -iname "*config*" -type f 2>/dev/null
find / -name "wp-config.php" -type f 2>/dev/null
ls ~/.ssh
```

# Techniques d'élévation de privilèges Linux dans des Box
Voici une compilation des techniques d'élévation de privilèges les plus intéressantes observées dans vos boxes Linux, organisées par catégories.
### Recherche de mots de passe dans les fichiers de configuration
Exemple (Fired):
```bash
# Rechercher des mots de passe dans les fichiers de configuration
grep --color=auto -rnw '/' -ie "PASSWORD" --color=always 2> /dev/null

# Vérifier les bases de données d'applications
ls -la /var/lib/*/
```
### Analyse des fichiers de logs
Exemple (Zipper):
```bash
# Vérifier les fichiers de logs pour des informations sensibles
cat /opt/backups/backup.log
```
### Historique des commandes
Exemple (Scrutiny):
```bash
# Vérifier l'historique des commandes des utilisateurs
find /home -name ".bash_history" -exec cat {} \;
```
### Recherche de fichiers cachés
Exemple (Scrutiny):
```bash
# Rechercher des fichiers cachés dans les répertoires utilisateurs
ls -la /home/*/
```
### Analyse des processus en cours d'exécution
Exemple (Flu, Ochima):
```bash
# Installer et utiliser pspy pour surveiller les processus sans privilèges root
wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.1/pspy64
chmod +x pspy64
./pspy64
```