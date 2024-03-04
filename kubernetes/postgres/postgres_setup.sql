-- Setup ingestion DB
CREATE DATABASE ingestion_db;
CREATE USER ingestion WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON DATABASE ingestion_db TO ingestion;
\c ingestion_db;
GRANT ALL on SCHEMA public to ingestion;

-- setup airflow DB
CREATE DATABASE airflow_db;
CREATE USER airflow WITH PASSWORD '123';
GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow;
-- PostgreSQL 15 requires additional privileges:
\c airflow_db;
GRANT ALL ON SCHEMA public TO airflow;

-- GiTea DB
CREATE DATABASE gitea;
CREATE USER gitea WITH PASSWORD 'gitea';
GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;
\c gitea;
GRANT ALL ON SCHEMA public TO gitea;

\c postgres;