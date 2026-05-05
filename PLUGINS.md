# Plugins

Librería's Moodle code lives in the `libreria-moodle` git submodule. Plugins are setup each as their own **git submodules inside `libreria-moodle`**, so each plugin's history stays in its own repo.


## Where plugins go
Each plugin is added under the Moodle directory that matches its plugin type:

- `public/mod/<plugin>` — activity modules
- `public/theme/<plugin>` — themes
- `public/payment/gateway/<plugin>` — payment gateways
- `public/question/type/<plugin>` — question types (qtype)

Other Moodle plugin types (`public/blocks/`, `public/local/`, `public/enrol/`, ...) should follow the same pattern — see [Moodle's plugin types](https://moodledev.io/docs/5.2/apis/plugintypes).

Our current plugins are at:
- `public/mod/attendance`
- `public/mod/customcert`
- `public/mod/hvp`
- `public/payment/gateway/btcpay`
- `public/payment/gateway/paypal`
- `public/payment/gateway/stripe`
- `public/question/behaviour`
- `public/question/type`
- `public/theme/scholastica`

## Adding a plugin
From `libreria-moodle`, add the submodule inside the correct directory, then commit, also commit on this repo so its up to date:

```bash
cd libreria-moodle
git submodule add <plugin-repo-url> public/mod/<plugin-name>
git commit -m "Add <plugin-name>"

cd ..
git add libreria-moodle
git commit -m "Bump libreria-moodle: add <plugin-name>"
```

Then install it in Moodle by booting the env and running the upgrade CLI:

```bash
docker compose up testmoodle
docker compose exec -ti testmoodle bash
php /root/libreria-moodle/admin/cli/upgrade.php --non-interactive
```

# Developing a plugin
Plugins should
- contain all the files required on the install directory in the root of the repository.
- specify in their `README.md` in which directory they are to be installed.

For example, if the plugin `my-custom-plugin` is to be installed at `public/mod/my-custom-plugin`, the repo must have the following structure:
```
my-custom-plugin
├── docs
├── lib.php
├── custom.php
└── README.md
```
So that the installation looks like the following:
```
libreria-moodle
├── .gitmodules --> [submodule "libreria-moodle"]
│                       path = libreria-moodle/public/mod/my-custom-plugin
│                       url = git@github.com:LibreriadeSatoshi/my-custom-plugin.git
└── public
    └── mod
        └── my-custom-plugin
            ├── .git
            ├── docs
            ├── lib.php
            ├── custom.php
            └── README.md
