#!/usr/bin/env bash
#
# Deploy custom-moodle@dev (including plugin submodules) to Lorien.
#
# Runs on the Lorien HOST (not inside the container). It refreshes the
# libreria-moodle checkout to the latest dev, updates submodules, runs the
# Moodle upgrade and purges caches. Idempotent and safe to re-run.
#
# Usage (on Lorien):   ~/moodle-test-environment/deploy.sh [--build]
# Usage (from laptop): ssh -t root@10.17.9.36 '~/moodle-test-environment/deploy.sh'
#
#   --build   also rebuild the container image (needed only when the
#             Dockerfile changed, e.g. new PHP extensions).
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKOUT="$REPO/libreria-moodle"
SERVICE="testmoodle"
BRANCH="dev"

# ── Single-writer lock: 5 people share Lorien, don't deploy concurrently. ─────
exec 9>/tmp/lorien-deploy.lock
if ! flock -n 9; then
    echo "❌ Another deploy is already running on Lorien. Try again in a moment."
    exit 1
fi

log() { printf '\n▶ %s\n' "$*"; }

# ── 1. Refresh the dev checkout ───────────────────────────────────────────────
log "Updating $CHECKOUT to origin/$BRANCH…"
cd "$CHECKOUT"

# mod_hvp's curl.php is overlaid at container start, so it shows as modified on
# every run. Discard it so the rebase never gets blocked. (Removed once ENG-358
# switches the overlay to a read-only bind mount.)
git checkout -- public/mod/hvp/classes/curl.php 2>/dev/null || true

git checkout "$BRANCH"
git pull --rebase --autostash origin "$BRANCH"
git submodule sync --recursive
git submodule update --init --recursive

# ── 2. Optional image rebuild ─────────────────────────────────────────────────
if [[ "${1:-}" == "--build" ]]; then
    log "Rebuilding container image (--build)…"
    cd "$REPO"
    docker compose up -d --build "$SERVICE"
    cd "$CHECKOUT"
fi

# ── 3. Locate the admin CLI dir inside the container (public/ layout varies) ───
cd "$REPO"
CLI=""
for base in /root/libreria-moodle/admin/cli /root/libreria-moodle/public/admin/cli; do
    if docker compose exec -T "$SERVICE" test -f "$base/upgrade.php" 2>/dev/null; then
        CLI="$base"
        break
    fi
done
if [[ -z "$CLI" ]]; then
    echo "❌ Could not find admin/cli/upgrade.php inside the container."
    exit 1
fi

# ── 4. Moodle upgrade + cache purge ───────────────────────────────────────────
log "Running Moodle upgrade + purging caches (CLI: $CLI)…"
docker compose exec -T "$SERVICE" php "$CLI/upgrade.php" --non-interactive
docker compose exec -T "$SERVICE" php "$CLI/purge_caches.php"

# ── 5. Summary ────────────────────────────────────────────────────────────────
log "Deployed. Submodule pointers:"
git -C "$CHECKOUT" submodule status public/auth/nostr

echo
echo "✅ Lorien is up to date with custom-moodle@$BRANCH."
echo "   Check: http://10.17.9.36:8888  (hard-reload with Ctrl+Shift+R)"
