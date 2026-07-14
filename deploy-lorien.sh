#!/usr/bin/env bash
#
# Deploy custom-moodle@dev (including plugin submodules) to Lorien.
#
# Runs on the Lorien HOST (not inside the container). It refreshes the
# libreria-moodle checkout to the latest dev, updates submodules, runs the
# Moodle upgrade and purges caches. Idempotent and safe to re-run.
#
# Usage (on Lorien):   ~/moodle-test-environment/deploy.sh [--build] [--dry-run]
# Usage (from laptop): ssh -t root@10.17.9.36 '~/moodle-test-environment/deploy.sh'
#
#   --build     also rebuild the container image (needed only when the
#               Dockerfile changed, e.g. new PHP extensions).
#   --dry-run   show what WOULD happen (incoming commits, submodule status,
#               which CLI it would use) without pulling, updating submodules,
#               rebuilding, upgrading or purging. Safe to run anytime.
#
set -euo pipefail

BUILD=0
DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --build)   BUILD=1 ;;
        --dry-run) DRY_RUN=1 ;;
        *) echo "Unknown option: $arg"; echo "Usage: deploy.sh [--build] [--dry-run]"; exit 2 ;;
    esac
done

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

# ── Locate the admin CLI dir inside the container (public/ layout varies). ─────
detect_cli() {
    local base
    for base in /root/libreria-moodle/admin/cli /root/libreria-moodle/public/admin/cli; do
        if docker compose exec -T "$SERVICE" test -f "$base/upgrade.php" 2>/dev/null; then
            echo "$base"
            return 0
        fi
    done
    return 1
}

# ── Dry-run: read-only preview, no mutations. ─────────────────────────────────
if [[ "$DRY_RUN" == "1" ]]; then
    cd "$CHECKOUT"
    log "DRY RUN — nothing will be changed."
    git fetch --quiet origin "$BRANCH"
    log "Commits that would be pulled ($BRANCH..origin/$BRANCH):"
    git log --oneline "$BRANCH..origin/$BRANCH" 2>/dev/null || echo "(switch to $BRANCH to compare)"
    log "Current submodule pointers:"
    git submodule status --recursive
    cli="$(detect_cli || true)"
    if [[ -n "$cli" ]]; then
        log "Would run: docker compose exec $SERVICE php $cli/{upgrade.php --non-interactive, purge_caches.php}"
    else
        log "Container not running or CLI not found — would run upgrade + purge once it's up."
    fi
    echo
    echo "✅ Dry run complete. Re-run without --dry-run to deploy."
    exit 0
fi

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
if [[ "$BUILD" == "1" ]]; then
    log "Rebuilding container image (--build)…"
    cd "$REPO"
    docker compose up -d --build "$SERVICE"
    cd "$CHECKOUT"
fi

# ── 3. Locate the admin CLI dir inside the container ───────────────────────────
cd "$REPO"
CLI="$(detect_cli || true)"
if [[ -z "$CLI" ]]; then
    echo "❌ Could not find admin/cli/upgrade.php inside the container."
    exit 1
fi

# ── 4. Moodle upgrade + cache purge ───────────────────────────────────────────
log "Running Moodle upgrade + purging caches (CLI: $CLI)…"
docker compose exec -T "$SERVICE" php "$CLI/upgrade.php" --non-interactive
docker compose exec -T "$SERVICE" php "$CLI/purge_caches.php"

# ── 5. Summary ────────────────────────────────────────────────────────────────
log "Deployed. Submodule pointers (check plugin versions here):"
git -C "$CHECKOUT" submodule status --recursive

echo
echo "✅ Lorien is up to date with custom-moodle@$BRANCH."
echo "   Check: http://10.17.9.36:8888  (hard-reload with Ctrl+Shift+R)"
