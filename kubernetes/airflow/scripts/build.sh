if [ -z "$CLUSTER_IP" ]; then
    echo "CLSUTER_IP not set, exiting"
    exit 1
fi

image_id=$(ls ../docker | awk '{print $1}' | grep ".dockerfile"  | cut -d. -f1)

echo "$image_id"

if [[ !$image_id -eq "" ]]; then
    echo "could not find dockerfile in format '<image_id>.dockerfile' in current folder"
    exit 1
fi

image_tag="$CLUSTER_IP:30500/$image_id"

docker build -f ../docker/$image_id.dockerfile -t $image_tag ../docker

if [[ $? -eq 0 ]]; then
    docker push $image_tag
else
    echo "failed to build image, push skipped"
fi
