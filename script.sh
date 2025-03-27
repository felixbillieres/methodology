#!/bin/bash

# Se placer à la racine du repo
cd "$(git rev-parse --show-toplevel)"

# Trouver tous les fichiers avec l'extension .md.md dans tous les sous-dossiers
find . -type f -name "*.md.md" | while read -r file; do
  # Nouveau nom sans la double extension
  new_name="${file%.md.md}.md"
  
  # Vérifier si un fichier avec le bon nom existe déjà
  if [[ -e "$new_name" ]]; then
    echo "Le fichier $new_name existe déjà, suppression de $file."
    rm "$file"
  else
    echo "Renommage de $file en $new_name"
    mv "$file" "$new_name"
  fi
done

echo "Correction terminée."
