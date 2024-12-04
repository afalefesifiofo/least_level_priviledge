#!/bin/bash

# File JSON che contiene le configurazioni
JSON_FILE="droits_acces2.json"

# Funzione per ottenere le cartelle in base al livello
get_folders() {
  level=$1
  # Estrai le cartelle per il livello dal JSON
  folders=$(jq -r ".groups.\"$level\"[]" "$JSON_FILE")
  echo "$folders"
}

# Funzione per ottenere i permessi per un utente e un livello specifico
get_permissions() {
  user=$1
  level=$2
  # Estrai i permessi per l'utente e il livello specificato dal JSON
  permission=$(jq -r ".users.\"$user\".\"$level\"" "$JSON_FILE")
  echo "$permission"
}

# Funzione per creare l'utente (e gestire la password)
create_user() {
  user=$1
  password=$2
  
  # Controlla se l'utente esiste già
  if id "$user" &>/dev/null; then
    echo "L'utente $user esiste già."
  else
    # Crea l'utente (senza shell interattiva)
    useradd -m -s /bin/bash "$user"
    echo "$user:$password" | chpasswd
    echo "Utente $user creato."
  fi
}

# Funzione per creare i gruppi di livello (Niveau1, Niveau2, Niveau3)
create_groups() {
  # Crea i gruppi per ogni livello, se non esistono
  for level in "Niveau1" "Niveau2" "Niveau3"; do
    if getent group "$level" &>/dev/null; then
      echo "Il gruppo $level esiste già."
    else
      groupadd "$level"
      echo "Gruppo $level creato."
    fi
  done
}

# Funzione per aggiungere l'utente al gruppo
add_user_to_group() {
  user=$1
  group=$2
  
  # Aggiungi l'utente al gruppo
  usermod -aG "$group" "$user"
  echo "L'utente $user è stato aggiunto al gruppo $group."
}

# Funzione per creare le directory se non esistono
create_directories() {
  folder=$1
  # Verifica se la cartella esiste, se no, la crea
  if [ ! -d "$folder" ]; then
    mkdir -p "$folder"
    echo "Cartella $folder creata."
  else
    echo "La cartella $folder esiste già."
  fi
}

# Funzione per configurare i permessi per l'utente su ogni cartella
configure_permissions() {
  user=$1
  level=$2

  # Ottieni i permessi per l'utente e il livello
  permission=$(get_permissions "$user" "$level")

  if [ "$permission" == "null" ]; then
    echo "Nessun permesso configurato per $user al livello $level"
    return
  fi

  # Ottieni le cartelle per il livello
  folders=$(get_folders "$level")

  echo "Configurando permessi per $user al livello $level:"
  echo "Permessi: $permission"
  echo "Cartelle: $folders"

  # Aggiungi logica per applicare i permessi sulle cartelle
  for folder in $folders; do
    # Crea la cartella se non esiste
    create_directories "$folder"
    
    # Modifica i permessi sulle cartelle in base al valore di $permission
    if [[ "$permission" == *"r"* ]]; then
      chmod +r "$folder"
      echo "Permessi lettura aggiunti a $folder"
    fi
    if [[ "$permission" == *"w"* ]]; then
      chmod +w "$folder"
      echo "Permessi scrittura aggiunti a $folder"
    fi
    if [[ "$permission" == *"x"* ]]; then
      chmod +x "$folder"
      echo "Permessi esecuzione aggiunti a $folder"
    fi

    # Cambia la proprietà della cartella (opzionale)
    chown "$user:$user" "$folder"
  done
}

# Funzione principale
main() {
  # Definisci gli utenti e le password
  users=("Jeannette" "Magally" "Moyo" "Branktor" "Kinfack" "Domguia" "Joseph" "Abena" "Bosco" "Nams")
  password="defaultPassword"  # Sostituisci con una logica per generare o ottenere una password

  # Crea i gruppi
  create_groups

  for user in "${users[@]}"; do
    # Crea l'utente (passa una password temporanea)
    create_user "$user" "$password"

    # Aggiungi l'utente ai gruppi corretti
    for level in "Niveau1" "Niveau2" "Niveau3"; do
      permission=$(get_permissions "$user" "$level")
      if [ "$permission" != "null" ]; then
        add_user_to_group "$user" "$level"
      fi
    done

    # Configura i permessi per l'utente su ogni livello
    for level in "Niveau1" "Niveau2" "Niveau3"; do
      configure_permissions "$user" "$level"
    done
  done
}

# Esegui lo script
main
