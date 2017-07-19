FROM ceh-sos:1.0.0

MAINTAINER CEH <oss@ceh.ac.uk>

RUN curl -L -o sos-bundle.zip https://github.com/52North/sos/releases/download/v4.3.15/52n-sensorweb-sos-bundle-4.3.15.zip \
    && unzip -d sos-bundle sos-bundle.zip \
    && unzip -d sos-webapp sos-bundle/*/bin/target/*.war \
    && cp -R /tmp/tomcat-conf/* $CATALINA_HOME/conf/ \
    && cp -R /tmp/rest-api-config/* sos-webapp/WEB-INF/ \
    && cp -R sos-webapp/ $CATALINA_HOME/webapps/observations \
    && apt-get -y autoremove --purge \
    && apt-get clean \
    && cp -R /tmp/sos-config/configuration.db $CATALINA_HOME/webapps/observations/ \
    && cp -R /tmp/sos-config/datasource.properties $CATALINA_HOME/webapps/observations/WEB-INF \
    && cp -R /tmp/sos-config/helg-settings.json $CATALINA_HOME/webapps/observations/static/client/helgoland/settings.json \
    && rm -rf /tmp/* && rm -rf /usr/lib/node_modules && rm -rf /root/.npm 
