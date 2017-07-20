FROM ceh-sos:1.0.0

MAINTAINER CEH <oss@ceh.ac.uk>

# Ran separately from the rest of the processing, as it's desired to cache this
#  layer while working on the processing steps to avoid repeat downloads
RUN curl -L -o sos-bundle.zip https://github.com/52North/sos/releases/download/v4.4.0/52n-sensorweb-sos-bundle-4.4.0.zip

RUN unzip -d sos-bundle sos-bundle.zip \
    && unzip -d sos-webapp sos-bundle/*/bin/target/*.war \
    && cp -R tomcat-conf/* $CATALINA_HOME/conf/ \
    && cp -R sos-webapp/ $CATALINA_HOME/webapps/observations \
    && cp -R sos-config/configuration.db $CATALINA_HOME/webapps/observations/ \
    && cp -R sos-config/datasource.properties $CATALINA_HOME/webapps/observations/WEB-INF \
    && cp -R sos-config/helg-settings.json $CATALINA_HOME/webapps/observations/static/client/helgoland/settings.json \
    && cp -R rest-api-config/* $CATALINA_HOME/webapps/observations/WEB-INF/ \
    && rm -rf /tmp/*
