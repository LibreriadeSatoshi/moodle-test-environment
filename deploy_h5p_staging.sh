#!/bin/bash

# ==============================================================================
# Automated Deployment Script: H5P Update (STAGING / DOCKER)
# ==============================================================================
# This script is adapted to test the full deployment flow in the local 
# docker compose environment.
# 
# Usage:
#   cd /home/euler/Projects/B4OS/moodle-test-environment
#   chmod +x deploy_h5p_staging.sh
#   ./deploy_h5p_staging.sh
# ==============================================================================

set -e

# Docker environment variables
MOODLE_DIR="/root/libreria-moodle"
# Removed '-it' to avoid TTY issues during script execution
DOCKER_CMD="docker compose exec testmoodle bash -c"

echo "=========================================================="
echo " INITIATING H5P DEPLOYMENT TEST IN STAGING (DOCKER)"
echo "=========================================================="

echo "=> [1/11] Enabling maintenance mode..."
$DOCKER_CMD "php $MOODLE_DIR/admin/cli/maintenance.php --enable"

echo "=> [2/11] Applying cherry-picks (Converting mod_hvp to submodule)..."
echo "   (Skipped in staging: already on the correct 'dev' branch)"

echo "=> [3/11] Initializing and fetching mod_hvp submodule (v1.28.1)..."
echo "   (Skipped in staging: submodule is already initialized locally)"

echo "=> [4/11] Fixing file and directory permissions..."
echo "   (Skipped in staging: commands run as root inside the container)"

echo "=> [5/11] Applying double-slash patch to factory.php..."
# Run the patch directly with php -r inside the container
$DOCKER_CMD "php -r '
\$f = \"$MOODLE_DIR/public/h5p/classes/factory.php\";
if (file_exists(\$f)) {
    \$c = file_get_contents(\$f);
    if (strpos(\$c, \"preg_replace\") === false) {
        \$c = str_replace(
            \"->out();\",
            \"->out();\n            \\\$url = preg_replace(\\\"~(%2F|\\\\\\\\/)$~\\\", \\\"\\\", \\\$url);\",
            \$c
        );
        file_put_contents(\$f, \$c);
        echo \"Double-slash patch applied successfully.\\n\";
    } else {
        echo \"Double-slash patch was already applied.\\n\";
    }
}
'"

echo "=> [6/11] Enabling slash arguments in Moodle..."
$DOCKER_CMD "php $MOODLE_DIR/admin/cli/cfg.php --name=slasharguments --set=1"

echo "=> [7/11] Running Moodle Upgrade (Database migrations)..."
$DOCKER_CMD "php $MOODLE_DIR/admin/cli/upgrade.php --non-interactive"

echo "=> [8/11] Reinstalling H5P libraries from official Hub (--force)..."
$DOCKER_CMD "php $MOODLE_DIR/scripts/h5p-tools/reinstall_libraries.php --reinstall --force"

echo "=> [9/11] Purging Moodle caches..."
$DOCKER_CMD "php $MOODLE_DIR/admin/cli/purge_caches.php"

echo "=> [10/11] Running health verification (Check Libraries)..."
$DOCKER_CMD "php $MOODLE_DIR/scripts/h5p-tools/check_libraries.php"

echo "=> [11/11] Disabling maintenance mode..."
$DOCKER_CMD "php $MOODLE_DIR/admin/cli/maintenance.php --disable"

echo "=========================================================="
echo " DEPLOYMENT TEST FINISHED SUCCESSFULLY!"
echo " If no errors occurred, H5P should be working on localhost."
echo "=========================================================="
