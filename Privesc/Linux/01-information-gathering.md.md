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
