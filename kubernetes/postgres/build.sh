image_id=$(ls | awk '{print $1}' | grep ".dockerfile"  | cut -d. -f1)

echo "$image_id"

if [[ !$image_id -eq "" ]]; then
    echo "could not find dockerfile in format '<image_id>.dockerfile' in current folder"
    exit
fi

docker build -f $image_id.dockerfile -t $CLUSTER_IP:30500/$image_id .

if [[ $? -eq 0 ]]; then
    docker push $CLUSTER_IP:30500/$image_id
else
    echo "failed to build image, push skipped"
fi
