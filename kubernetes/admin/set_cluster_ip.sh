cur_context=$(kubectl config current-context)

filter="cluster[].name = $cur_context"
ip=$(kubectl config view | yq '.clusters[] | select(.name=="default") | .cluster.server' | cut -d'/' -f3 | cut -d':' -f1)
echo "$ip"
export CLUSTER_IP="$ip"
