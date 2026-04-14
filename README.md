# Moodle Test Environment
Local Docker environment for testing Moodle plugins and testing upgrades. Can restore backups to replicate the production environment.


## Requirements
- Docker and Docker Compose
- SSH access to the Moodle host (`~/.ssh/moodle-mvp.pem`) — only needed to fetch backups. Ask @Ivan for it.
- The `libreria-moodle` submodule must be initialized:
  ```bash
  git submodule update --init
  ```


## Running a local clean test environment
Boots a fresh Moodle install with Librería's plugins against an empty Postgres database.

1- Start the container:
  ```bash
  docker compose up testmoodle
  ```
2- Wait for the `Started.` log line, then open `http://localhost:8888`.
3- Log in with the seeded admin account:
  - user: `admin`
  - password: `Admin1234!`
4- To get a shell inside the container:
  ```bash
  docker compose exec -ti testmoodle bash
  ```
5- To stop and clean up:
  ```bash
  docker compose down
  ```

> Note: the Postgres password is `pass`. The database is recreated on every `up`, so always `down` before restarting.


## Running a local test environment replicating the production environment
Boots Moodle restoring the latest backup from `backup/` into the database.

1- Start the container:
  ```bash
  docker compose up testmoodle-restore
  ```
2- Wait for the `Started.` log line, then open `http://localhost:8888`.
3- Log in with the seeded admin account:
  - user: `admin`
  - password: `Admin1234!`
4- To stop and clean up:
  ```bash
  docker compose down
  ```

> Note: both services bind port 8888, so only run one at a time.
