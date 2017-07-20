FROM ceh-sos:1.0.0

MAINTAINER CEH <oss@ceh.ac.uk>

# Ran separately from the rest of the processing, as it's desired to cache this
#  layer while working on the processing steps to avoid repeat downloads
RUN curl -L -o sos-bundle.zip https://github.com/52North/sos/releases/download/v4.3.15/52n-sensorweb-sos-bundle-4.3.15.zip

RUN unzip -d sos-bundle sos-bundle.zip \
    && unzip -d sos-webapp sos-bundle/*/bin/target/*.war \
    && cp -R /tmp/tomcat-conf/* $CATALINA_HOME/conf/ \
    && cp -R /tmp/rest-api-config/* sos-webapp/WEB-INF/ \
    && cp -R sos-webapp/ $CATALINA_HOME/webapps/observations \
    && cp -R /tmp/sos-config/configuration.db $CATALINA_HOME/webapps/observations/ \
    && cp -R /tmp/sos-config/datasource.properties $CATALINA_HOME/webapps/observations/WEB-INF \
    && cp -R /tmp/sos-config/helg-settings.json $CATALINA_HOME/webapps/observations/static/client/helgoland/settings.json \
    && cp -R /tmp/sos-config/settings.json $CATALINA_HOME/webapps/observations/static/client/jsClient/settings.json \
    && rm -rf /tmp/*
