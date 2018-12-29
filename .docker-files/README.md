# Docker Files
This files are directly load to the docker image's root directory.
Any files except `*.sh` and `*.exclude` will get ignored during the repository upgrade. 

## `entrypoint.sh`
This file is the default entrypoint of each start of Friendica.
It automatically checks the following things:

-	If the image is for a develop or Release candidate, checkout the latest sources from github if necessary
-	Setup the SMTP settings for SSMTP
-	Check if an upgrade is necessary (due to new checkout or because of a new version)
-	Check if it's a fresh installation and initialize Friendica
-	Check if auto install is set and execute the auto-installer
-	Read all environment variables and combine them with `local.config.php`

## `cron.sh`
This file is for overwriting the default entrypoint.
It starts the daemon of the current Friendica instance.

**Warning** Currently only **one** daemon service is allowed to run!

## `upgrade.exclude`
Contains all files to exclude during an upgrade or a fresh installation of Friendica (f.e. `local.config.php`)