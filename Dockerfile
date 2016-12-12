FROM tomcat:8

MAINTAINER oss@ceh.ac.uk

# Download and deploy the 52N SOS app
RUN wget http://52north.org/downloads/send/3-sos/507-52n-sensorweb-sos-bundle-4-3-8
RUN mv 507-52n-sensorweb-sos-bundle-4-3-8 507-52n-sensorweb-sos-bundle-4-3-8.zip
RUN unzip 507-52n-sensorweb-sos-bundle-4-3-8.zip
RUN mv 52n-sensorweb-sos-bundle-4.3.8/bin/target/52n-sos-webapp##4.3.8.war /usr/local/tomcat/webapps/observations.war
RUN rm -R 52n-sensorweb-sos-bundle-4.3.8
RUN rm -R 507-52n-sensorweb-sos-bundle-4-3-8.zip

# Using the settings file rather than a fully automatic build as there is
#  a descrepancy between the REST API setup instructions and the current WAR
#  file deployed
# https://wiki.52north.org/SensorWeb/SensorObservationServiceIVDocumentation#C1_41_Building_a_Preconfigured_Service

