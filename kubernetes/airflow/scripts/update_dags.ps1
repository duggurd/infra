$podId = kubectl get pods -n airflow | Select-String "airflow-depl.*Running" | ForEach-Object { $_.Line.Split()[0] }
Write-Host "$podId"

if (-not [string]::IsNullOrEmpty($podId)) {
    # remove and add dags
    kubectl exec "$podId" -n airflow -c airflow -- find /opt/airflow/dags -mindepth 1 -delete
    write-host "$podid"
    kubectl cp ../dags ${podId}:/opt/airflow -c airflow -n airflow
} else {
    Write-Host "could not find 'airflow-depl' pod"
    exit 1
}

# container_name = $(kubectl get pods airflow-depl-c6f57d86c-fl74x -o jsonpath='{.spec.containers[*].name)
if ($LASTEXITCODE -eq 0) {
    kubectl exec "$podId" -n airflow -c airflow -- airflow dags reserialize
}