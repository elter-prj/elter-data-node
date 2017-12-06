-- Settings for PG10
-- Machine: 12 cores, 9GB RAM
ALTER SYSTEM SET max_connections = 10;
ALTER SYSTEM SET shared_buffers = '2304MB';
ALTER SYSTEM SET effective_cache_size = '6912MB';
ALTER SYSTEM SET work_mem = '117964kB';
ALTER SYSTEM SET maintenance_work_mem = '576MB';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '2GB';
ALTER SYSTEM SET checkpoint_completion_target = '0.9';
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = '100';