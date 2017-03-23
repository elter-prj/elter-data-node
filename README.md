# eLTER Data Node

Within this directory there is a `make` file that is used to control the building, deploying, and stopping of the SOS system.  It is comprised of two docker images, the first being the Tomcat image that the 52N SOS WAR file runs on, while the second is the one where the PostgreSQL database is hosted.

The design for this docker-compose setup came from 52N's pre-configured setup, found at the [ConnectinGEO](https://github.com/52North/ConnectinGEO) GitHub repository.

# Pre-requisites

Running on an Ubuntu host, it is necessary to have Docker and make installed.  The community edition of Docker can be installed using the instructions found [here](https://docs.docker.com/engine/installation/linux/ubuntu/#install-docker), it is **not** necessary to install Docker Compose.  Make can be installed using:

`sudo apt-get install make`

# Build, Deploy, Stop

To build and deploy the containers in one command, execute the following in this folder:

`make deploy`

This will use the `docker-compose.yml` file and the corresponding `Dockerfile`'s to build the images and deploy them in one step.  The SOS app will be available on the localhost, attached to the port defined in the `docker-compose.yml` file using the `host-port:container-port` mapping.

To stop the containers, execute:

`make stop`

This will stop, but not remove the data held in the database.  The database data files are stored on a volume on the host, rather than the container, so if re-building with a different starting database, it is necessary to remove the existing volume - this will remove all data entered in the previous sessions that the container has been active.

## Initial Usernames &Passwords

For this example setup, the database user is `postgres`, and the password is `postgres`.  For the 52N app, the admin user is `sos_admin` and the password is `asdf892342nk.a9`

# Configuration

## 52North SOS

The SOS app deploys with two bundled files, the first provides the metadata for the SOS configuration, the second provides the database connection details respectively:

* `configuration.db`
* `datasource.properties`

The `configuration.db` file is a binary SQlite file, while `datasource.properties` is a text file.

### Metadata & Passwords

The configuration.db holds the metadata and application password.  This metadata is currently setup for CEH, as is the application password.  To use your own metadata, you have two choices.  First you could deploy an instance of the 52N SOS WAR application, say on your localhost, configure that instance with your metadata and admin's username (if you wanted to change the username), then copy that `configuration.db` file into this project.  The second choice would be to use SQlite to edit the fields in the database.

To change the SOS app password, login to the admin section using the above credentials, open the `Settings` page and navigate to the `Credentials` tab where the change can be made.

The database connection details in `datasource.properties` holds the PostgreSQL connection details including the database username and password.  These values must match the variable values provided in the `docker-compose.yml` for the PostgreSQL instance.

## Postgresql

The username and password variable values are provided in the `docker-compose.yml` file, while the `Dockerfile` for the database image contains the database name.  The `Dockerfile` also contains the command to copy the database image to the container.  Currently this is an empty SOS database for version 4.3.8 of 52N's SOS app.

If you wish to deploy a version of this database with data, you would have to first take a backup of a 52N SOS database that holds the observation data using, for example:

`pg_dump -Fp sos -f /tmp/sos.sql`

You would then have to edit the (in our instance) three SQL statements for creating schemas, as these are already created, from:

`CREATE SCHEMA schema-name`

To:

`CREATE SCHEMA IF NOT EXISTS schema-name`

Now you can gzip the file, and replace the existing `sos.sql.gz` file with your new data filled version, rebuild the image, and it will now deploy with that data.