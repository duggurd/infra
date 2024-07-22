# Airlfow deployment

## TODO

1. Translate deployment and resources to Terraform
2. Fix kubernetes certs
3. Add connection to ingestion database, or write direclty to clickhouse probably?
    - Need to create a clickhouse config object
4. Schedule ingestion of finn data to clickhouse from `testing.ipynb`
5. Create simple ingestion metadata db to track ingested files in MinIO
6. Move DAGs to separate repo, use Jenkins for CICD