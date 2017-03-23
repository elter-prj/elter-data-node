FROM 52north/sos:4.3.8

MAINTAINER CEH <oss@ceh.ac.uk>

RUN apt-get -y install netcat && apt-get clean

# Copy configuration files for app and client
COPY sos-config/configuration.db $CATALINA_HOME/webapps/52n-sos-webapp/
COPY sos-config/datasource.properties $CATALINA_HOME/webapps/52n-sos-webapp/WEB-INF
COPY sos-config/helg-settings.json $CATALINA_HOME/webapps/52n-sos-webapp/static/client/helgoland/settings.json
COPY sos-config/header.jsp $CATALINA_HOME/webapps/52n-sos-webapp/WEB-INF/views/common/header.jsp

# Copy and setup env script
COPY tomcat-bin/* $CATALINA_HOME/bin
RUN mv /usr/local/tomcat/webapps/52n-sos-webapp /usr/local/tomcat/webapps/observations
RUN chmod +x $CATALINA_HOME/bin/*.sh
