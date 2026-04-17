# Moodle Test Environment
Local Docker environment for testing Moodle plugins and testing upgrades. Can restore backups to replicate the production environment.


## Requirements
- Docker and Docker Compose
- SSH access to the Moodle host (`~/.ssh/moodle-mvp.pem`) — only needed to fetch backups. Ask @Ivan for it.
- The `libreria-moodle` submodule must be initialized:
  ```bash
  git submodule update --init
  ```


## Running a local clean test environmentgit submodule update --init --recursive
Boots a fresh Moodle install with Librería's plugins against an empty Postgres database.

1- Clone this repo with:
```
git clone --recurse-submodules git@github.com:LibreriadeSatoshi/moodle-test-environment.git
```
2- Start the container:
  ```bash
  docker compose up testmoodle
  ```
3- Wait for the `Started.` log line, then open `http://localhost:8888`.
4- Log in with the seeded admin account:
  - user: `admin`
  - password: `Admin1234!`
5- To get a shell inside the container:
  ```bash
  docker compose exec -ti testmoodle bash
  ```
6- To stop and clean up:
  ```bash
  docker compose down
  ```

> Note: the Postgres password is `pass`. The database is recreated on every `up`, so always `down` before restarting.
> Note: the service binds port 8888.


## Running a local test environment replicating the production environment
To boot Moodle restoring the latest backup from `backup/` into the database, follow the same steps, but instead of `testmoodle` use `testmoodle-restore` on the second steop.
> Note: this service also bind port 8888, so only run one at a time.


## Updating the test environment's state
Each time the test environment is booted, it will be restored from the latest backup in the `backup` directory, which is **git ignored** by default.

To update the information on the test environment follow these steps:
- boot up the environment and make all the changes you want
- get a shell inside the environment:
```
docker compose exec -ti testmoodle-restore bash
```
- run the backup tool, the backup will be stored in the host's `backup` directory
```
./backup-moodle.sh
```
- Done! The next time you boot up the environment, it will be restored from your latest backup.

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
