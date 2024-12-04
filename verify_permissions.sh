#!/bin/bash

# Percorso del file JSON
JSON_FILE="droits_acces2.json"

# Funzione per ottenere i permessi di un utente su un livello
get_user_permission() {
  user=$1
  level=$2
  jq -r ".users.\"$user\".\"$level\"" "$JSON_FILE"
}

# Funzione per verificare i permessi di un utente su un livello specifico
verify_permissions() {
  user=$1
  level=$2

  # Ottieni il permesso dell'utente per il livello
  actual_permission=$(get_user_permission "$user" "$level")

  # Se l'utente non ha un permesso definito per questo livello, salta la verifica
  if [[ "$actual_permission" == "null" ]]; then
    echo "L'utente $user non ha permessi definiti per $level. Nessuna verifica necessaria."
  else
    echo "L'utente $user ha permessi $actual_permission su $level."
  fi
}

# Funzione principale
main() {
  # Ottieni la lista degli utenti dal file JSON
  users=$(jq -r '.users | keys[]' "$JSON_FILE")
  levels=("Niveau1" "Niveau2" "Niveau3")

  for user in $users; do
    for level in "${levels[@]}"; do
      # Verifica i permessi per l'utente sul livello
      verify_permissions "$user" "$level"
    done
  done
}

# Esegui lo script
main
