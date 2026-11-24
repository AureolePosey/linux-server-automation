
# shellcheck shell=bash

# Fonction interne de journalisation
_log() {
    local level="${1:?Niveau de log manquant}"
    local message="${2-}"
    local log_dir="${LOG_DIR:-/var/log/devops-tool}"
    local log_file
    local timestamp

    log_file="$log_dir/common.log"

    # Essayer le dossier et le fichier de logs principal
    if ! mkdir -p "$log_dir" 2>/dev/null ||
       ! touch "$log_file" 2>/dev/null; then

        # Utiliser le dossier personnel en secours
        log_dir="${HOME}/.local/state/devops-tool"
        log_file="$log_dir/common.log"

        if ! mkdir -p "$log_dir" 2>/dev/null ||
           ! touch "$log_file" 2>/dev/null; then

            printf "Impossible d'ecrire dans le dossier des logs.\n" >&2
            return 1
        fi
    fi

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Construire et enregistrer le message
    if [[ "$level" == "ERROR" ]]; then
        printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message" |
            tee -a "$log_file" >&2
    else
        printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message" |
            tee -a "$log_file"
    fi
}

# Journalisation INFO
log_info() {
    _log "INFO" "${1-}"
}

# Journalisation WARN
log_warn() {
    _log "WARN" "${1-}"
}

# Journalisation ERROR
log_error() {
    _log "ERROR" "${1-}"
}

# Afficher une erreur et arrêter le programme
die() {
    local message="${1:-Une erreur est survenue}"

    log_error "$message"
    exit 1
}

# Vérifier les privilèges root
require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        die "Cette operation necessite les privileges root. Utilisez sudo."
    fi
}

# Vérifier l'existence d'une commande
command_exists() {
    [[ $# -gt 0 ]] && command -v "$1" >/dev/null 2>&1
}
