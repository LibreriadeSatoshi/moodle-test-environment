# Moodle Test Environment
Local Docker environment for testing Moodle plugins and testing upgrades. Can restore backups to replicate the production environment. To set up or develop a plugin, see [PLUGINS.md](PLUGINS.md).


## Requirements
- Docker and Docker Compose
- [Add your ssh key to github account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- Clone with submodules:
  ```bash
  git clone --branch {branch} --recurse-submodules git@github.com:LibreriadeSatoshi/moodle-test-environment.git
  ```
  If you already cloned without submodules:
  ```bash
  git submodule update --init
  ```
  Then:
  ```bash
  cd libreria-moodle
  git checkout {branch}
  ```
  Fill in `{branch}` with `dev` or `main`, depending of which environment you want to test locally.
- SSH access to the Moodle host (`~/.ssh/moodle-mvp.pem`) — only needed to fetch backups. Ask @Ivan for it.


## How it works
The environment is split across three Compose services that share two named volumes (`pgdata`, `moodledata`):

- `testmoodle-fresh` — **one-time init**: creates the database and runs Moodle's installer against an empty schema.
- `testmoodle-restore` — **one-time init**: creates the database and restores the latest backup from `backup/`.
- `testmoodle` — **normal run**: just starts Postgres and Apache against the already-prepared volumes.

All three publish port `8888`, so only one runs at a time. Pick an init service the first time, then use `testmoodle` for every subsequent boot.


## Initializing the environment
Pick **one** of the two init paths. You only do this once — the data lives in named volumes after that.


### Option A — fresh empty install
Boots a fresh Moodle install with Librería's plugins against an empty Postgres database.
```bash
docker compose up testmoodle-fresh
```

### Option B — restore from a production backup
Boots Moodle with the latest backup in `backup/` restored into the database.
```bash
docker compose up testmoodle-restore
```

In both cases, wait for the `Started.` log line, then open `http://localhost:8888` and log in with:
- user: `admin`
- password: `Admin1234!`

> Note: the Postgres password is `pass`.


## Running the environment
Once initialized, boot the env without re-installing anything:
```bash
docker compose up testmoodle
```
Stop it with:
```bash
docker compose down
```
The named volumes persist across `down`/`up`, so the next `up testmoodle` resumes the same state.

To get a shell inside the running container:
```bash
docker compose exec -ti testmoodle bash
```


## Resetting the environment
To wipe the database and `moodledata` and start over, remove the named volumes:
```bash
docker compose down -v
```
Then re-run one of the two init services above.

> Note: `down -v` is also required when switching between fresh and restore — the init services assume empty volumes and will error on a populated database.


## Updating the test environment's state
The `backup/` directory is **git ignored**. To capture the current state as a new backup:

1- Boot the environment and make all the changes you want.

2- Get a shell inside the environment:
```bash
docker compose exec -ti testmoodle bash
```

3- Run the backup tool — the backup is stored in the host's `backup/` directory:
```bash
./backup-moodle.sh
```

The next time you initialize with `testmoodle-restore`, it will pick up the latest backup automatically.


## Updating the test environment's code
Libreria's Moodle code lives in the `libreria-moodle` git submodule. To pull in upstream changes:

1- Fetch the latest commits on the submodule's tracked branch:
```bash
git submodule update --remote libreria-moodle
```
2- Commit the bumped submodule pointer so others get the same version:
```bash
git add libreria-moodle
git commit -m "Bump libreria-moodle"
```
3- Restart the container to pick up the new code:
```bash
docker compose down && docker compose up testmoodle
```

> Note: after pulling this repo on another machine, run `git submodule update --init` to sync the submodule to the committed pointer.

> Note: schema changes from new/updated plugins won't apply automatically on a restored env. After bumping the submodule, run Moodle's upgrade CLI:
> ```bash
> docker compose exec -ti testmoodle bash
> php /root/libreria-moodle/public/admin/cli/upgrade.php --non-interactive
> ```
