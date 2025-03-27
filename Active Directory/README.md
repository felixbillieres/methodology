# Méthodologie d'Audit Active Directory

Cette méthodologie présente une approche structurée pour auditer un environnement Active Directory, en identifiant les vulnérabilités courantes et en appliquant des techniques d'exploitation efficaces.

## Structure de la méthodologie

1. **Reconnaissance et découverte initiale**
   - Identifier le domaine, les sous-domaines et l'infrastructure réseau
   - Collecter des informations publiques (DNS, enregistrements IP, etc.)

2. **Énumération du domaine**
   - Découvrir les utilisateurs, groupes et ordinateurs
   - Identifier les contrôleurs de domaine et services exposés
   - Comprendre la structure organisationnelle

3. **Obtention d'un premier accès**
   - Empoisonnement LLMNR/NBT-NS
   - Password spraying et brute force
   - Exploitation d'accès anonymes

4. **Énumération post-compromission**
   - Cartographie avec BloodHound
   - Analyse des permissions et ACLs
   - Identification des chemins d'attaque

5. **Techniques d'élévation de privilèges**
   - Exploitation des ACLs vulnérables
   - Attaques d'authentification (Kerberoasting, AS-REP Roasting)
   - Abus de configurations de service

6. **Mouvement latéral**
   - Techniques de déplacement entre systèmes
   - Exploitation des comptes à privilèges
   - Contournement des restrictions

7. **Compromission de domaine**
   - DCSync et extraction de hashes
   - Attaques avancées (Golden/Silver Tickets)
   - Exploitation de vulnérabilités critiques

8. **Documentation et reporting**
   - Synthèse des vulnérabilités découvertes
   - Recommandations de remédiation
   - Preuves de concept

Chaque section détaillée dans les pages suivantes contient les commandes, outils et techniques spécifiques permettant de réaliser un audit complet et efficace.