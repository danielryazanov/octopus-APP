#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# teardown.sh – Remove all Octopus App containers, networks, and (optionally)
#               volumes
# Usage:  ./scripts/teardown.sh [--volumes]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

REMOVE_VOLUMES=false
for arg in "$@"; do
  [[ "$arg" == "--volumes" ]] && REMOVE_VOLUMES=true
done

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }

cd "$ROOT_DIR"

if $REMOVE_VOLUMES; then
  warn "⚠  This will PERMANENTLY DELETE all data volumes (MongoDB, Prometheus, Grafana)."
  read -rp "Are you sure? (yes/no): " CONFIRM
  [[ "$CONFIRM" == "yes" ]] || { echo "Aborted."; exit 0; }
  info "Stopping and removing containers, networks, and volumes..."
  docker compose down -v --remove-orphans
else
  info "Stopping and removing containers and networks (data volumes preserved)..."
  docker compose down --remove-orphans
fi

info "✅  Teardown complete."
