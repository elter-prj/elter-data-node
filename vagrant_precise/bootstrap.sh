# /usr/bin/env bash

# Parameters for creating database and database user
DBROLE='sos'
DBPASSWORD='sos-role-password'
DBNAME='sos'

# Locale issues with Precise
# =======================================================================
#
# https://ubuntuforums.org/showthread.php?t=2268614
sudo locale-gen en_GB.UTF-8


# Install Postgresql + Postigs
# =======================================================================
# Necessary for Geonode - need to fix locale first or cluster not created

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install postgresql-9.1 postgresql-9.1-postgis unzip -y

# Install Geonode
# =======================================================================
#
# The keyfile is not necessary, as we can accept unsecured downloads.
# http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x8CE87CDB9FBF90A1
# sudo apt-key add /vagrant/keyfile.txt
# Installing geonode also installs openjdk-6 (we will need 7 for Tomcat)

sudo add-apt-repository ppa:geonode/release -y
sudo apt-get update
sudo apt-get install geonode -y --force-yes

# Setup Geonode
# =======================================================================
# Create user, set IP

#  The username will, I assume, need to be changed to a user on your VM
geonode createsuperuser --username=vagrant --email=test@vagrant.vagrant --noinput
sudo geonode-updateip 0.0.0.0

# Update /etc/geonode/local_settings.py from :
# ALLOWED_HOSTS=['0.0.0.0', 'localhost']
# to:
# ALLOWED_HOSTS=['0.0.0.0', 'localhost','127.0.0.1']

sudo sed -i 's/ALLOWED_HOSTS=["0.0.0.0", "localhost"]/ALLOWED_HOSTS=["0.0.0.0", "localhost", "127.0.0.1"]/g' /etc/geonode/local_settings.py

# Setup 52N SOS database
# =======================================================================
#
# Create the database, install Postgis (using older version, as when add
#  postgresql apt source, it installs multiple versions of postgresql.

# Create DB with Postgis
sudo -u postgres -H -- createdb $DBNAME
sudo -u postgres -H -- createlang plpgsql sos
sudo -u postgres -H -- psql -d sos -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql
sudo -u postgres -H -- psql -d sos -f /usr/share/postgresql/9.1/contrib/postgis-1.5/spatial_ref_sys.sql
sudo -u postgres -H -- psql -d sos -f /usr/share/postgresql/9.1/contrib/postgis_comments.sql

# Create role, basic permissions, modify with parameterised passsword
#  and individual table roles.
sudo -u postgres -H -- psql -c "CREATE ROLE $DBROLE SUPERUSER"
sudo -u postgres -H -- psql -c "ALTER ROLE $DBROLE ENCRYPTED PASSWORD '$DBPASSWORD'"
sudo -u postgres -H -- psql -c "ALTER ROLE $DBROLE LOGIN"


# Download and setup the 52N war
# =======================================================================

# Install openjdk-7 for Tomcat, and set it to the default
sudo apt-get install openjdk-7-jdk openjdk-7-jre -y
sudo update-alternatives --config java <<< '2'

wget http://52north.org/downloads/send/3-sos/507-52n-sensorweb-sos-bundle-4-3-8
mv 507-52n-sensorweb-sos-bundle-4-3-8 507-52n-sensorweb-sos-bundle-4-3-8.zip
unzip 507-52n-sensorweb-sos-bundle-4-3-8.zip
sudo mv 52n-sensorweb-sos-bundle-4.3.8/bin/target/52n-sos-webapp##4.3.8.war /var/lib/tomcat7/webapps/observations.war

# Install StarterKit
# =======================================================================

# After the below, we now receive a "500 internal server error" when viewing the HTTP port
sudo pip install starterkit
sudo echo "SITENAME = 'eLTER'" >> /etc/starterkit/local_settings.py
sudo echo "SITEURL = '127.0.0.1'" >> /etc/starterkit/local_settings.py
sudo echo "ALLOWED_HOSTS = ['0.0.0.0','localhost','127.0.0.1']" >> /etc/starterkit/local_settings.py
sudo cp /etc/apache2/sites-available/geonode /etc/apache2/sites-available/geonode.backup
sudo sed -i "s|/var/www/geonode/wsgi/geonode.wsgi|/usr/local/lib/python2.7/dist-packages/geosk/wsgi.py|" /etc/apache2/sites-available/geonode

sudo pip uninstall django-rosetta -y
sudo pip install django-rosetta==0.7.4

sudo service apache2 restart

sk syncdb
sk migrate

# Setup starterkit
# =============================================================================

# The following commands/setup must be done manually, as it is not possible
#  to parameterize them

# sk collectstatic
