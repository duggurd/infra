FROM postgres:alpine 

ENV POSTGRES_PASSWORD=postgres
ADD postgres_setup.sql /docker-entrypoint-initdb.d/
RUN psql -U postgres -i /docker-entrypoint-initdb.d/postgres_setup.sql 