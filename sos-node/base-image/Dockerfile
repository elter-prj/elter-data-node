FROM tomcat:9-alpine

# This image is a modified version of the sos and sos-configured Docker image
# definitions found at the following 52North repository:
# https://github.com/52North/ConnectinGEO

MAINTAINER CEH <oss@ceh.ac.uk>

# Install netcat, used in the tomcat-bin based script used to check the database
#  is up and accepting connections before starting the 52North webapp.

RUN apk add --update \
    netcat-openbsd \
    curl \
    unzip \
    && rm -rf /var/cache/apk/*

# Set the working directory and copy all the configuration files to the image.
WORKDIR /tmp
COPY rest-api-config/* rest-api-config/
COPY tomcat-conf/* tomcat-conf/
COPY sos-config/* sos-config/
COPY tomcat-bin/* tomcat-bin/

# Copy the database connection checking script and set its permissions.
COPY tomcat-bin/* $CATALINA_HOME/bin
RUN chmod +x $CATALINA_HOME/bin/*.sh
