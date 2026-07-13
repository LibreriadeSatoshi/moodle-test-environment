# Deploying to Lorien

Lorien mirrors `custom-moodle@dev`. Instead of running the pull / submodule /
upgrade / purge commands by hand, use the one-command deploy script.

## Level 1 — one-command deploy (available now)

On Lorien:

```bash
~/moodle-test-environment/deploy.sh
```

Or from your laptop (ZeroTier):

```bash
ssh -t root@10.17.9.36 '~/moodle-test-environment/deploy.sh'
```

What it does (see [`deploy.sh`](../deploy.sh)):

1. Takes a lock so two people can't deploy at once.
2. Discards the recurring `mod_hvp/classes/curl.php` overlay, then
   `git pull --rebase --autostash origin dev`.
3. `git submodule sync/update --recursive`.
4. Detects the container's admin CLI dir and runs `upgrade.php` + `purge_caches.php`.
5. Prints the resulting `auth/nostr` submodule pointer.

Pass `--build` when the Dockerfile changed (e.g. a new PHP extension):

```bash
~/moodle-test-environment/deploy.sh --build
```

**Tip:** add a shell alias on your machine so it's a single word:

```bash
alias lorien-deploy="ssh -t root@10.17.9.36 '~/moodle-test-environment/deploy.sh'"
```

## Level 2 — auto-deploy on push to `dev` (planned)

Goal: every push to `custom-moodle@dev` redeploys Lorien with no manual step,
matching the `dev → Lorien` branch model.

Recommended approach — **GitHub Actions self-hosted runner on Lorien**:

1. Register a self-hosted runner on Lorien (Settings → Actions → Runners in the
   `custom-moodle` repo). It only needs outbound HTTPS to GitHub, which Lorien
   already has.
2. Add a workflow to `custom-moodle` (not this repo), e.g. `.github/workflows/deploy-lorien.yml`:

   ```yaml
   name: Deploy to Lorien
   on:
     push:
       branches: [dev]
   concurrency:
     group: lorien-deploy      # matches deploy.sh's flock: never overlap
     cancel-in-progress: false
   jobs:
     deploy:
       runs-on: [self-hosted, lorien]
       steps:
         - run: ~/moodle-test-environment/deploy.sh
   ```

The workflow just calls the same `deploy.sh`, so there is a single source of
truth for how a deploy works. Decision to confirm before enabling: are we OK
with **any** push to `dev` touching Lorien? (Given the current model, yes — but
WIP should go to feature branches, not `dev`.)

Alternative without GitHub Actions: a `systemd` timer on Lorien that runs
`git -C libreria-moodle fetch` every N minutes and calls `deploy.sh` when
`origin/dev` moved. Simpler infra, but polling instead of instant.
