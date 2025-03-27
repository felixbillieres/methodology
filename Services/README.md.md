# Méthodologie d'Attaque des Services Courants

Cette méthodologie présente une approche structurée pour l'énumération et l'exploitation des services couramment rencontrés lors de tests d'intrusion et examens de certification.

## 📋 Table des matières

### Services réseau et protocoles
- [FTP (21/TCP)](#ftp-2tcp)
- [SSH (22/TCP)](#ssh-22tcp)
- [SMTP/POP3/IMAP (25,110,143/TCP)](#smtppop3imap-25110143tcp)
- [DNS (53/TCP/UDP)](#dns-53tcpudp)
- [SMB/CIFS (139,445/TCP)](#smbcifs-139445tcp)
- [LDAP (389/TCP)](#ldap-389tcp)
- [SQL Databases (1433,3306/TCP)](#sql-databases-14333306tcp)
- [RDP (3389/TCP)](#rdp-3389tcp)
- [WinRM (5985,5986/TCP)](#winrm-59855986tcp)

### Applications Web
- [Content Management Systems (CMS)](#content-management-systems-cms)
  - [WordPress](#wordpress)
  - [Joomla](#joomla)
  - [Drupal](#drupal)

La navigation entre les sections est conçue pour être fluide et intuitive. Chaque service comprend des étapes d'énumération, des vecteurs d'attaque et des techniques d'exploitation.