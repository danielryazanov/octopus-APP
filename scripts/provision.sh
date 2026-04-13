#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# provision.sh – Provision the full Octopus App architecture from scratch
# Usage:  ./scripts/provision.sh [--prod]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROD=false
for arg in "$@"; do
  [[ "$arg" == "--prod" ]] && PROD=true
done

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── Prerequisites ─────────────────────────────────────────────────────────────
info "Checking prerequisites..."
command -v docker  >/dev/null 2>&1 || error "Docker is not installed. See https://docs.docker.com/get-docker/"
docker compose version >/dev/null 2>&1 \
  || docker-compose version >/dev/null 2>&1 \
  || error "Docker Compose is not installed."

# ── Environment file ──────────────────────────────────────────────────────────
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  warn ".env file not found – copying from .env.example"
  cp .env.example .env
  warn "⚠  Please edit .env and set strong passwords before continuing in production!"
  if $PROD; then
    error "Refusing to start in --prod mode with default passwords. Edit .env first."
  fi
fi

# ── Build & Start ─────────────────────────────────────────────────────────────
if $PROD; then
  info "Starting PRODUCTION stack..."
  docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
  docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build --remove-orphans
else
  info "Starting DEVELOPMENT/STAGING stack..."
  docker compose up -d --build --remove-orphans
fi

# ── Wait for services ─────────────────────────────────────────────────────────
info "Waiting for services to become healthy..."
MAX_WAIT=120
ELAPSED=0
until curl -sf http://localhost/healthz >/dev/null 2>&1; do
  if (( ELAPSED >= MAX_WAIT )); then
    warn "Services did not become healthy within ${MAX_WAIT}s"
    docker compose ps
    docker compose logs --tail=50 app
    exit 1
  fi
  echo -n "."
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done
echo ""

info "✅  All services are up!"
echo ""
echo -e "${GREEN}──────────────────────────────────────────────────────${NC}"
echo -e "  🌐  App:        http://localhost"
echo -e "  📊  Prometheus: http://localhost:9090"
echo -e "  📈  Grafana:    http://localhost:3001  (admin / see .env)"
echo -e "${GREEN}──────────────────────────────────────────────────────${NC}"
echo ""

# ── Quick validation ─────────────────────────────────────────────────────────
info "Running smoke tests..."
APPLE_QTY=$(curl -sf http://localhost/api/fruits/apples | python3 -c "import sys,json; print(json.load(sys.stdin)['qty'])" 2>/dev/null || echo "FAIL")
if [[ "$APPLE_QTY" == "5" ]]; then
  info "✅  Smoke test passed: apples qty = ${APPLE_QTY}"
else
  warn "⚠  Smoke test: expected apples qty=5, got '${APPLE_QTY}'"
fi
