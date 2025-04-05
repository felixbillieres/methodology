### Restricted Environments
#### Citrix Breakout
Basic Methodology for break-out:

1. Gain access to a `Dialog Box`.
2. Exploit the Dialog Box to achieve `command execution`.
3. `Escalate privileges` to gain higher levels of access.
There are multiple ways to open dialog box in windows using tools such as Paint, Notepad, Wordpad, etc. We will cover using `MS Paint` as an example for this section.

Run `Paint` from start menu and click on `File > Open` to open the Dialog Box. With the windows dialog box open for paint, we can enter the [UNC](https://learn.microsoft.com/en-us/dotnet/standard/io/file-path-formats#unc-paths) path `\\127.0.0.1\c$\users\pmorgan` under the File name field, with File-Type set to `All Files` and upon hitting enter we gain access to the desired directory.
### Accessing SMB share from restricted environment
Start a SMB server from the Ubuntu machine using Impacket's `smbserver.py` script.
```shell-session
root@ubuntu:/home/htb-student/Tools# smbserver.py -smb2support share $(pwd)
```
Back in the Citrix environment, initiate the "Paint" app, navigate to the "File" menu and select "Open", thereby prompting the Dialog Box to appear. Within this Windows dialog box associated with Paint, input the UNC path as `\\10.13.38.95\share` into the designated "File name" field. Ensure that the File-Type parameter is configured to "All Files." Upon pressing the "Enter" key, entry into the share is achieved.