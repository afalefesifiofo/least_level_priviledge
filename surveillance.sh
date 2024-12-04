#!/bin/bash

# Fichier JSON de description
JSON_FILE="droits_acces2.json"
LOG_FILE="access_log.txt"

# Lecture des paramètres d'entrée
SECURITY_LEVEL="$1"  # Niveau de sécurité maximal à surveiller (ex. 2)
DURATION="$2"        # Durée de surveillance en secondes

# Vérifications des paramètres
if [[ -z "$SECURITY_LEVEL" || -z "$DURATION" ]]; then
  echo "Usage: $0 <niveau_max> <durée_en_secondes>"
  exit 1
fi

# Obtenir les répertoires à surveiller à partir du fichier JSON
get_directories() {
  level="$1"
  jq -r ".groups | to_entries[] | select(.key | match(\"Niveau[0-9]+\")) | select(.key | capture(\"[0-9]+\") | .[\"0\"] <= $level) | .value[]" "$JSON_FILE"
}

# Fonction principale
main() {
  # Obtenir les répertoires à surveiller
  directories=$(get_directories "$SECURITY_LEVEL")
  
  if [[ -z "$directories" ]]; then
    echo "Aucun répertoire à surveiller pour le niveau $SECURITY_LEVEL ou inférieur."
    exit 0
  fi

  # Convertir la durée en timestamp pour arrêt automatique
  end_time=$(( $(date +%s) + DURATION ))

  echo "Surveillance en cours... (durée : $DURATION secondes)"
  echo "Événements consignés dans : $LOG_FILE"

  # Créer ou vider le fichier log
  > "$LOG_FILE"

  # Lancer la surveillance avec inotifywait
  while [[ $(date +%s) -lt $end_time ]]; do
    echo "$directories" | xargs -n1 inotifywait -e access -e open --format '%T %w%f %e %u' --timefmt '%Y-%m-%d %H:%M:%S' -q >> "$LOG_FILE" 2>/dev/null &
    sleep 1  # Intervalle pour vérifier la fin de durée
  done

  # Fin de la surveillance
  echo "Surveillance terminée."
}

# Exécuter la fonction principale
main
