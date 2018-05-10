# Docker Files for FIWARE Labs (partially) flavoured CKAN

[CKAN](https://github.com/ckan/ckan) is a powerful Data Management system used to power Open Data catalogues across the world, including many national
portals. It has many publishing and curating features and offers a full API to access both the metadata and certain data formats.

Full documentation for CKAN can be found at http://docs.ckan.org.

## How to use these Docker files with Docker Compose

This requires [Docker Compose](https://docs.docker.com/compose/) to be installed.

Docker Compose will take care of running and linking the following services:

* Postgres
* Solr
* Redis
* DataPusher
* CKAN itself

There are a few things to be done before launching the instance:

1. Edit `.env` and change variables to suit your needs:
	- Change `PASSWORD` and `RO_PASSWORD`
	- Add the CKAN_SITE_URL
	- If you wish to create an initial CKAN Admin, change `CKAN_SYSADMIN` to `true` and add needed information

2. If needed, add any aditional override settings in `configs.ini` (like SMTP configuration or OAuth settings)

Once you've completed the above steps, launch your CKAN instance with Docker Compose

	docker-compose build --pull --force-rm
	docker-compose up -d

After a couple of minutes, your CKAN instance should be available at the url defined in `CKAN_SITE_URL`

## Features

There are a number of things that set this build apart from others availble (including official images);

1. Respects Docker best practices and attempts to seperate as much as possible each service into its own container;
2. Automates the creation of the initial sysadmin user (no need to exec into a container to add the initial sysadmin user);
3. Properly sets up the datastore database permissions and user;
4. Doesn't bundle a static `production.ini` (which re-uses CKAN_UUID and CKAN_secret entries) and yet still allows easy overrides of default configs created by `paster make-config ckan`