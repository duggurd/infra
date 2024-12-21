from typing import Mapping
from dbt.artifacts.resources.types import NodeType
from dbt.cli.main import dbtRunner
from dbt.contracts.graph.manifest import Manifest
from datetime import datetime
import minio

from dbt.contracts.graph.nodes import ModelNode
from airflow.decorators import dag, task

def get_manifests_from_minio(minio_endpoint: str|None = None) -> Mapping[str, Manifest]:

    minio_client = minio.Minio(
        "minio.minio:9000" if minio_endpoint is None else minio_endpoint,
        "minioadmin",
        "minioadmin",
        secure=False
    )
    
    manifests = {}
    
    manifest_paths = [o.object_name for o in minio_client.list_objects("dbt", "manifests")]
    
    if manifest_paths != []:
        manifests = {
            p.split("/")[-1]: Manifest.from_msgpack(minio_client.get_object("dbt", p).data) 
            for p in manifest_paths 
            if p is not None
        }

    return manifests

def dynamic_dbt_build_model_task(node: ModelNode, dbtrunnner: dbtRunner):
    @task(
        task_id=f"build_{node.unique_id}"
    )
    def build_model(model_unique_id: str, dbtrunner: dbtRunner):
        res = dbtrunner.invoke(["build", "--select", model_unique_id])

    return build_model(node.unique_id, dbtrunnner)

def dag_from_dbt_manifest(manifest: Manifest):
    @dag(
        dag_id=f"dbt_exec_{manifest.metadata.project_name}",
        start_time=datetime(2024, 1, 1),
        interval="0 0 * * *"
    )
    def dbt_dag(manifest: Manifest):
        dbtrunner = dbtRunner(manifest=manifest)

        tasks = {}
        for node in manifest.nodes.values():

            if node.resource_type == NodeType.Model:
                tasks[node.unique_id] = dynamic_dbt_build_model_task(node, dbtrunner)
        

        for node in manifest.nodes.values():
            for depends_on_node in node.depends_on_nodes:
                if depends_on_node.startswith("model."):
                    tasks[depends_on_node]() >> tasks[node.unique_id]()

    return dbt_dag(manifest)

manifests = get_manifests_from_minio()
for manifest in manifests.values():
    dag = dag_from_dbt_manifest(manifest)()