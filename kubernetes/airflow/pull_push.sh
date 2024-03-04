if [ -z "$CLUSTER_IP" ]; then
    echo "CLUSTER_IP not set, exiting"
    exit 1
fi

image_id="apache/airflow:slim-latest"

echo "$image_id"

if [[ -z "$image_id"  ]]; then
    echo "no image_id provided"
    exit 1
fi

docker pull "$image_id"
docker tag "$image_id" $CLUSTER_IP:30500/airflow

docker push $CLUSTER_IP:30500/airflow
