from airflow.decorators import task, dag
import datetime
from ingest_finn import datasets
from dbt.cli.main import dbtRunner


# @dag(
#     dag_id="finn_etl",
#     schedule=datasets,
#     start_date=datetime(2024, 1, 1),
#     catchup=False
# )
# def finn_etl():
#     for dataset in datasets:
#         @task(task_id=f"DBT_{dataset.uri}")
#         def dbt_runner():
#             pass
        
#         dbt_runner()