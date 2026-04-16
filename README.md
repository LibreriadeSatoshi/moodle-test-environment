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
