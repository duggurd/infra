-- Setup ingestion DB
CREATE DATABASE IF NOT EXISTS ingestion_db;
CREATE USER ingestion WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON DATABASE ingestion_db TO ingestion;
\c ingestion_db;
CREATE SCHEMA IF NOT EXISTSfinn;
GRANT ALL on SCHEMA finn to ingestion;
ALTER DEFAULT PRIVILEGES IN SCHEMA finn GRANT ALL PRIVILEGES ON TABLES TO ingestion;

-- setup airflow DB
CREATE DATABASE IF NOT EXISTS airflow_db;
CREATE USER airflow WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow;
-- PostgreSQL 15 requires additional privileges:
\c airflow_db;
GRANT ALL ON SCHEMA public TO airflow;

-- GiTea DB
CREATE DATABASE IF NOT EXISTS gitea;
CREATE USER gitea WITH PASSWORD 'gitea';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
\c gitea;
GRANT ALL ON SCHEMA public TO gitea;

\c postgres;