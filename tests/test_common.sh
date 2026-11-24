#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOG_DIR="/tmp/devops-common-tests"

source "$PROJECT_DIR/lib/common.sh"

# Préparation des tests
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/common.log"

# Test des trois niveaux de logs
log_info "Test INFO"
log_warn "Test WARN"
log_error "Test ERROR"

# Vérifier que le fichier de logs existe
[[ -f "$LOG_FILE" ]]

# Vérifier que les trois messages sont présents
grep -q "\[INFO\] Test INFO" "$LOG_FILE"
grep -q "\[WARN\] Test WARN" "$LOG_FILE"
grep -q "\[ERROR\] Test ERROR" "$LOG_FILE"

echo "TEST LOGS : OK"


# Test de command_exists
if command_exists curl; then
    echo "TEST COMMAND EXISTS (curl) : OK"
else
    echo "TEST COMMAND EXISTS (curl) : FAILED"
    exit 1
fi

if command_exists commande_inexistante; then
    echo "TEST COMMANDE INEXISTANTE : FAILED"
    exit 1
else
    echo "TEST COMMANDE INEXISTANTE : OK"
fi

# Test de die
if bash -c 'source "$1"; LOG_DIR="$2"; die "Erreur de test"' _ "$PROJECT_DIR/lib/common.sh" "$LOG_DIR" 2>/dev/null; then
    echo "TEST DIE : FAILED"
    exit 1
else
    echo "TEST DIE : OK"
fi

# Test de require_root avec un utilisateur normal
if bash -c 'source "$1"; LOG_DIR="$2"; require_root' _ "$PROJECT_DIR/lib/common.sh" "$LOG_DIR" 2>/dev/null; then
    echo "TEST REQUIRE ROOT (utilisateur normal) : FAILED"
    exit 1
else
    echo "TEST REQUIRE ROOT (utilisateur normal) : OK"
fi

# Test de require_root avec root
if sudo bash -c 'source "$1"; LOG_DIR="$2"; require_root' _ "$PROJECT_DIR/lib/common.sh" "$LOG_DIR" 2>/dev/null; then
    echo "TEST REQUIRE ROOT (root) : OK"
else
    echo "TEST REQUIRE ROOT (root) : FAILED"
    exit 1
fi

# Test : source ne doit produire aucun effet secondaire
SOURCE_TEST_DIR="/tmp/devops-source-test-$$"

rm -rf "$SOURCE_TEST_DIR"

SOURCE_OUTPUT=$(LOG_DIR="$SOURCE_TEST_DIR" bash -c \
    'source "$1"' _ "$PROJECT_DIR/lib/common.sh" 2>&1)

if [[ -z "$SOURCE_OUTPUT" ]] && [[ ! -e "$SOURCE_TEST_DIR" ]]; then
    echo "TEST SOURCE SANS EFFET SECONDAIRE : OK"
else
    echo "TEST SOURCE SANS EFFET SECONDAIRE : FAILED"
    exit 1
fi
