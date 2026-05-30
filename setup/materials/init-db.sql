-- Hive用
CREATE USER hiveuser WITH PASSWORD 'hivepassword';
CREATE DATABASE hive_meta OWNER hiveuser;

-- Ranger用
CREATE USER rangeruser WITH PASSWORD 'rangerpassword';
CREATE DATABASE ranger_db OWNER rangeruser;