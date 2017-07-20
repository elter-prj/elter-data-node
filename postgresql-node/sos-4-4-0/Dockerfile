FROM mdillon/postgis:9.5

ADD settings.sql /docker-entrypoint-initdb.d/zzz-settings.sql
ADD sos.sql.gz /docker-entrypoint-initdb.d/zzz-sos.sql.gz
ADD sos-mods.sql /docker-entrypoint-initdb.d/zzz-z-sos-mods.sql
