# /usr/bin/env bash

sudo locale-gen en_GB.UTF-8
sudo locale-gen it_IT.UTF-8

# add old geonode repository
sudo add-apt-repository -s 'deb http://ppa.launchpad.net/geonode/release/ubuntu precise main'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 8CE87CDB9FBF90A1
sudo apt-get update

sudo apt-get install -y geoserver-geonode
sudo apt-get install -y apache2 libapache2-mod-wsgi
sudo apt-get install -y postgresql-9.3 postgresql-9.3-postgis-2.1 python-psycopg2
sudo apt-get install -y python-dev python-imaging python-lxml python-pyproj python-shapely python-nose python-httplib2 python-pip python-software-properties
sudo apt-get install -y  git gettext
sudo apt-get libxml2-dev libxslt-dev
sudo apt-get install libgeos-dev
sudo apt-get install unzip

# install geonode package (temporarily and without dependencies)
cd /tmp/
sudo apt-get  download geonode
sudo POSTGIS_SQL_PATH=/usr/share/postgresql/9.3/contrib/postgis-2.1 POSTGIS_SQL=postgis.sql dpkg --force-all -i geonode_2.0.1+thefinal0_all.deb
cd -
# apt-get -f install # verificare questo se serve veramente

# remove geonode package
sudo touch /etc/apache2/sites-available/default.conf
sudo cp /etc/apache2/sites-available/geonode /etc/apache2/sites-available/geonode.conf
sudo apt-get remove -y geonode

sudo pip install -vvv django-pagination==1.0.7

sudo pip install geonode==2.0
sudo pip install starterkit


# downgrade django-extension
sudo pip install -vvv  django-extensions==1.1.1
# sudo pip install -vvv geonode-user-messages==0.1.5

sudo a2dissite 000-default
sudo a2ensite geonode
sudo service apache2 reload

sudo mkdir /var/www/geonode/wsgi/
sudo ln -s /usr/local/lib/python2.7/dist-packages/geosk/wsgi.py /var/www/geonode/wsgi/geonode.wsgi

django-admin.py syncdb --settings=geonode.settings --noinput

# fix some migrate issues
sudo -u postgres psql -c "insert into django_content_type (name, app_label, model) values ('contact role', 'layers', 'contactrole');" geonode
sudo -u postgres psql -c "create table core_objectrole(id serial);" geonode
sudo -u postgres psql -c "create table core_genericobjectrolemapping(id serial);" geonode
sudo -u postgres psql -c "create table core_objectrole_permissions(id serial);" geonode
sudo -u postgres psql -c "create table core_userobjectrolemapping(id serial);" geonode

django-admin.py  migrate --settings=geonode.settings

sk syncdb
sk migrate

sudo mkdir -p /etc/geonode/media
sudo sk collectstatic --noinput


# django extension downgrade
pip install -vvv django-extensions==1.1.1


# Download and setup the 52N war
wget http://52north.org/downloads/send/3-sos/507-52n-sensorweb-sos-bundle-4-3-8
mv 507-52n-sensorweb-sos-bundle-4-3-8 507-52n-sensorweb-sos-bundle-4-3-8.zip
unzip 507-52n-sensorweb-sos-bundle-4-3-8.zip
sudo mv 52n-sensorweb-sos-bundle-4.3.8/bin/target/52n-sos-webapp##4.3.8.war /var/lib/tomcat7/webapps/observations.war
