# eLTER Data Node

This repository holds the Docker image definition files, and the configuration and deployment files to provision the eLTER central data node.

# Deployment

Within this directory there is a `Makefile` that is used to control the building, deploying, and stopping of the SOS system.

Running on an Ubuntu host, it is necessary to have Docker and make installed.  The community edition of Docker can be installed using the instructions found [here](https://docs.docker.com/engine/installation/linux/ubuntu/#install-docker), it is **not** necessary to install Docker Compose.  Make can be installed using:

`sudo apt-get install make`

# Build, Deploy, Stop

To build the containers execute the following in this folder:

`make build`

This will build the base SOS image using Docker, and the database and the versioned SOS instances using `docker-compose.yml`.  After changing the `Dockerfile` of any image, it is necessary to call `make deploy` to incorporate the changes.

Once built, running containers can be created by using:

`make deploy`

The SOS app will be available on the localhost, attached to the port defined in the `docker-compose.yml` file using the `host-port:container-port` mapping.  Currently this is port 8080.

To stop the containers, use:

`make stop`

This will stop, but not remove the data held in the database.  If you want to completely remove the data from the database, which is necessary if you are then going to rebuild, you must run:

`make stop-clear`

## 52North

The 52North SOS deployment consists of a Tomcat based container for the web application, and a Postgis based container for the database.  These containers and the Docker Compose file were modified from the [52North repository for ConnectinGEO](https://github.com/52North/ConnectinGEO).

Currently there is the option to build a 4.3.15 SOS container, or a 4.4.0 SOS container.  The database structure between these releases is different, and so they require different empty or provisioned databases.  

### Preconfigured SOS Deployment

There is a base image that holds all the configuration files needed for the SOS, and two images for the two versions of 52North's SOS currently used.  These two versions build on the base image, as many of the files used are the same between them.

#### Configuration Files

##### Application

The Dockerfile for the SOS deployment, both versions [4.3.x](sos-node/SOS-4-3-15/Dockerfile) and [4.4.x](sos-node/SOS-4-4-0/Dockerfile), use existing configuration files for the application and the Helgoland client.  The application file are:

* [configuration.db](sos-node/base-image/sos-config/configuration.db): stores the settings metadata provided on install and the application username and password
* [datasource.properties](sos-node/base-image/sos-config/datasource.properties): stores the connection settings to the PostgreSQL database

If you want to use these Docker images, but with your own configuration settings and database settings, you will have to copy these files from your existing SOS deployment and use them to replace the existing files in the base image [folder](sos-node/base-image/sos-config).

The initial database user is `postgres`, and the password is `postgres`.  For the 52N app, the admin user is `sos_admin` and the password is `asdf892342nk.a9`, please change once you have setup and secured your connection over https.  The postgres credentials are set in the `docker-compose.yml` file, while the SOS credentials are set in the application.  To change the SOS app password, login to the admin section using the credentials , open the `Settings` page and navigate to the `Credentials` tab where the change can be made.

The database connection details in `datasource.properties` hold the PostgreSQL connection details including the database username and password.  These values must match the variable values provided in the `docker-compose.yml` for the PostgreSQL instance.

##### Client

The Helgoland client settings are found in the file:

* [helg-settings.json](sos-node/base-image/sos-config/helg-settings.json)

These settings are self-explanatory, modify as you wish.

##### REST API

The REST API, versions one and two, can be configured through the files found in the base image folder.  The files are:

* [timeseries-api-v1-beans.xml](sos-node/base-image/rest-api-config/spring/timeseries-api_v1-beans.xml): API V1 configuration file
* [spi-impl-dao_common.xml](sos-node/base-image/rest-api-config/sprin/spi-impl-dao_common.xml): API V2 configuration file

For this project the only change has been to serviceDescription or name element, for V1 and V2 respectively, to provide a suitable ID for the central data node API service in the Helgoland and DIP clients.

#### Database

The database for each of the SOS releases is specific to the given release.  While the install forms of the SOS application allow for the upgrading of 4.3.x databases to 4.4.x specification, the empty database packaged here was created by the 4.4.0 application.

As the database versions are different, there are two different directories, one for each of the two releases we are building with.  If in `docker-compose.yml` you decide to build `sos-node/SOS-4-4-0/.` then you should also build `postgresql-node/SOS-4-4-0/.`.  Similarly, do the same with the 4.3.15 if that's what you choose to deploy.

If you wish to deploy a version of this database with data, you would have to first take a backup of a 52N SOS database that holds the observation data using, for example:

`pg_dump -Fp sos -f /tmp/sos.sql`

You would then have to edit the (in our instance) three SQL statements for creating schemas at the top of this file, as these are already created, from:

`CREATE SCHEMA schema-name`

To:

`CREATE SCHEMA IF NOT EXISTS schema-name`

Now you can gzip the file, and replace the existing `sos.sql.gz` file with your new data filled version, rebuild the image, and it will now deploy with that data.

#### Settings

While the settings have been preconfigured, it is likely still necessary for the user to change the following SOS settings:

* Admin Menu -> Settings Page -> Transaction Security Tab: Is security active, do you filter IP's, do you use the security token.
* Admin Menu -> Settings Page -> Service Tab: Does the SOS URL need updating?
* Admin Menu -> Settings -> Operations Page: Select the operations allowable on the SOS node.

# Data Handling

The contents of the data handling directory are used to populate the 52N SOS server.
