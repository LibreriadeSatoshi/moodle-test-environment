# Playbook for upgrading Moodle

## Preparations
1- To do the upgrade you will need:
  - The host's IP or domain name.
  - `ssh` access, either a `.pem` private key, or your own public key to be added to `authorized_keys`.
  Ask @Ivan for these.

2- Use `ssh` to log into the host machine, and look for the database password.
  ```bash
  ssh -i ~/.ssh/moodle-mvp.pem ubuntu@moodle.host.machine
  sudo cat moodle/config.php
  ```
  Look for `$CFG->dbpass` and note it down.

3- To make a backup, copy the `scripts/backup-moodle.sh` script to the moodle host.
  ```bash
  scp -i ~/.ssh/moodle-mvp.pem scripts/backup-moodle.sh ubuntu@moodle.host.machine:.
  ssh -i ~/.ssh/moodle-mvp.pem ubuntu@moodle.host.machine
  ```

4- Configure the database password, and run the backup script.
  ```bash
  export PGPASSWORD='<dbpass>'
  sudo -E ./backup-moodle.sh
  ```
  Your backup will be stored at `backup/<YYYY-MM-DD-HHMM>/`.


## Local Test Environment
All the upgrade steps can be run locally on a docker test environment, to set it up, follow these steps:

1- Fetch a backup from the host machine:
```bash
# show available backups
./scripts/fetch-moodle-backup.sh
# fetch a specific backup
./scripts/fetch-moodle-backup.sh <YYYY-MM-DD-HHMM>
```

2- Start the test environment:
```bash
docker compose up
```
Moodle should be available at `http://localhost:8888` after the log shows `Started.`.

To get into the container run:
```bash
docker compose exec -ti testmoodle bash
```

When finished, stop and cleanup the container:
```bash
docker compose down
```

> Note: for the local test environment, the Postgres database password is set to `pass`.
> Note: the test environment always restores from the local backup when starting, restarting a container without a proper cleanup will not work properly.

## Upgrade Steps
1- First let's set Moodle in maintenance mode:
  ```bash
  cp moodledata/climaintenance.html.disabled moodledata/climaintenance.html
  cd moodle
  sudo /usr/bin/php admin/cli/maintenance.php --enable
  ```

2.1- There are two ways to upgrade, using the upgrade script directly, which will upgrade to the latest stable version:
   ```bash
   sudo /usr/bin/php admin/cli/upgrade.php
   ```

2.2- Or first pulling the bleeding edge version from git, and then running the upgrade script:
  ```bash
  # Assuming we have not made any changes to Moodle's source code,
  # the checkout discards any permission change made along the way.
  git checkout .
  git pull
  sudo /usr/bin/php admin/cli/upgrade.php
  ```
  Then follow the script's instructions.

2.3- If the script fails with the assertion `PHP setting max_input_vars must be at least 5000.`, increase the value in the `php.ini` file:
  ```bash
  echo "max_input_vars = 5000" >> /etc/php/{php-version}/cli/php.ini
  ```
  or edit it manually, then run the upgrade script again.

3- Disable maintenance mode:
  ```bash
  sudo /usr/bin/php admin/cli/maintenance.php --disable
  ```

> Note: More information on the upgrade process via CLI can be found in the [Moodle documentation](https://docs.moodle.org/501/en/Administration_via_command_line)


## Backup restoration
In the event an upgrade fails, or you need to set up a previous version, you can restore from a backup.

1- From your own local machine copy the restoration script:
  ```bash
  scp -i ~/.ssh/moodle-mvp.pem scripts/restore-moodle.sh ubuntu@moodle.host.machine:.
  ```

2- Run the restoration script on the host machine:
  ```bash
  export PGPASSWORD='<dbpass>'
  # show available backups
  sudo -E ./restore-moodle.sh
  # restore the latest backup
  sudo -E ./restore-moodle.sh latest
  # restore a specific backup
  sudo -E ./restore-moodle.sh <YYYY-MM-DD-HHMM>
  ```
