FROM mdillon/postgis:9.5

ADD settings.sql /docker-entrypoint-initdb.d/zzz-settings.sql
ADD sos.sql.gz /docker-entrypoint-initdb.d/zzz-sos.sql.gz

# The mods file below is used to update an ECN populated database with the feature information
#  that was left out during its initial loading
ADD ecn-sos-mods.sql /docker-entrypoint-initdb.d/zzz-z-ecn-sos-mods.sql

# The mods file below is used to update a 4.3.x database to a 4.4.0 database
ADD sos-mods-4_3-to-4_4.sql /docker-entrypoint-initdb.d/zzz-z-sos-mods-4_3-to-4_4.sql

