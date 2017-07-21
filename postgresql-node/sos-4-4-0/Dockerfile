FROM mdillon/postgis:9.5

ADD settings.sql /docker-entrypoint-initdb.d/zzz-settings.sql
ADD sos.sql.gz /docker-entrypoint-initdb.d/zzz-sos.sql.gz

# The mods file is for an existing observation database with data specific updates
#  and 4.3.x to 4.4.0 database migration changes.  This is not necessary if you
#  are using an empty database and can be removed.
ADD sos-mods.sql /docker-entrypoint-initdb.d/zzz-z-sos-mods.sql
