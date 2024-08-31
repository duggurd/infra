# Infra

Kubernetes and general infrastructure

## Services

- Airflow 
    - Data ingestion
    - Data transformation
    - Other automation/scheduling
- PostgreSQL
    - For general metadata storage
    - General transactional storage
- Jenkins
    - CI/CD
- Docker container registry
- ClickHouse
    - Datawarehouse
    - Anallytics
- Trino
    - Distributed query engine
- Dremio
    - Distributed query engine/lakehouse

### Services to be added

- Grafana 
-    Data visuaization and monitoring 
- Kafka cluster
    - Data streaming
- Spark cluster
    - Data lakehouse processing
- Longhorn
    - Distributed kubernetes storage



## Accessing Services

Services are exposed via [TailScale](https://tailscale.com/) VPN

Download the client [here](https://tailscale.com/download)

Then you will be added to the network and can freely access the services