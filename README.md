# FiWare CKAN Docker Image

## Deploying Fiware - CKAN Docker Instance

1. Edit `.env` and change variables to suit your needs:
	- Change `PASSWORD` and `RO_PASSWORD`
	- Add the CKAN_SITE_URL
	- If you wish to create an initial CKAN Admin, change `CKAN_SYSADMIN` to `true` and add needed information

2. If needed, add any aditional override settings in `configs.ini` (like SMTP configuration or OAuth settings)
3. Launch using docker-compose with `docker-compose up --build --force-rm -d`

Enjoy!

## Features

There are a number of things that set this build apart from others availble (including official images);

1. Respects Docker best practices and attempts to seperate as much as possible each service into it's own container;
2. Automates the creation of the initial sysadmin user (no need to exec into a container to add the initial sysadmin user);
3. Properly sets up the datastore database permissions and user;
4. Doens't bundle a static `production.ini` (which re-uses CKAN_UUID and CKAN_secret entries) and yet still allows easy overrides of default configs created by `paster make-config ckan`