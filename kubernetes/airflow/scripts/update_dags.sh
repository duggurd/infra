pod_id=$(kubectl get pods -n airflow | grep "airflow-depl.*Running" | awk '{print $1}')
echo "$pod_id"

if [ -n "$pod_id" ]; then
    # remove and add dags
    kubectl exec "$pod_id" -n airflow -c airflow -- find /opt/airflow/dags -mindepth 1 -delete
    kubectl cp ../dags "$pod_id":/opt/airflow -c airflow -n airflow
else 
    echo "could not find 'airflow-depl' pod"
    exit 1
fi

# container_name = $(kubectl get pods airflow-depl-c6f57d86c-fl74x -o jsonpath='{.spec.containers[*].name)
if [ $? -eq 0 ]; then 
    kubectl exec "$pod_id" -n airflow -c airflow -- airflow dags reserialize
fi