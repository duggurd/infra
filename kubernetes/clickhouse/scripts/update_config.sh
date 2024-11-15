# currently using a custom PV with local-path storage class therefore copying directly to node (not ideal)

scp -r ../clickhouse-server/* root@homelab-1:/mnt/clickhouse-conf/


# pod_id=$(kubectl get pods -n clickhouse | grep "clickhouse.*Running" | awk '{print $1}')
# echo "$pod_id"
# exit 1

# if [ -n "$pod_id" ]; then
#     kubectl cp ../configuration/config.xml "$pod_id":/etc/clickhouse-server/config.xml -c clickhouse -n clickhouse
# else 
#     echo "could not find 'clickhouse' pod"
#     exit 1
# fi


# kubectl cp ./configuration/s3_config.xml clickhouse-99f6b4f4b-xz8ph:/etc/clickhouse-server/config.d/s3_config.xml -n clickhouse
