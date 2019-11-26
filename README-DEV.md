# Special settings for DEV/RC images

The `*-dev` and `*-rc` branches are having additional possibilities to get the latest sources of Friendica. 

## Possible Environment Variables

The following environment variables are possible for these kind of images too:

**Develop/Release Candidat Settings**
-	`FRIENDICA_UPGRADE` If set to `true`, a develop or release candidat node will get updated at startup.
-	`FRIENDICA_REPOSITORY` If set, a custom repository will be chosen (Default: `friendica`)
-	`FRIENDICA_ADDONS_REPO` If set, a custom repository for the addons will be chosen (Default: `friendica`)
-	`FRIENDICA_VERSION` If set, a custom branch will be chosen (Default is based on the chosen image version)
-	`FRIENDICA_ADDONS` If set, a custom branch for the addons will be chosen (Default is based on the chosen image version)

## Updating to a newer version

You don't need to pull the image for each commit in [friendica](https://github.com/friendica/friendica/).
Instead, the release candidate or develop branch will get updated if no installation was found or the environment variable `FRIENDICA_UPGRADE` is set to `true`.

It will clone the latest Friendica version and copy it to your working directory.
