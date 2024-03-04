pod_id=$(kubectl get pods | grep "airflow-depl" | awk '{print $1}')
echo "$pod_id"

if [ -z "$pod_id" ]; then
    echo "could not find 'airflow-depl' pod"
    exit 1    
fi


# kubectl exec "$pod_id" -c airflow -- rm /tmp/requirements.txt

kubectl cp ./requirements.txt "$pod_id":/tmp -c airflow

# container_name = $(kubectl get pods airflow-depl-c6f57d86c-fl74x -o jsonpath='{.spec.containers[*].name)
if [ $? -eq 0 ]; then 
    echo "pip installin"
    kubectl exec "$pod_id" -c airflow -- pip install -r /tmp/requirements.txt
fi