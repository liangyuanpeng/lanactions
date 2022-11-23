# standard bash error handling
set -o errexit;
set -o pipefail;
set -o nounset;
# debug commands
set -x;

sed -i -E -e 's/docker/'"$CLUSTER_HOST"'/g' drone/kind-config


kind create cluster --name "$CLUSTER_NAME" --config drone/kind-config --wait 1m

docker ps -a
cat ${KUBECONFIG}
#replace localhost or 0.0.0.0 in the kubeconfig file with "docker", in order to be able to reach the cluster through the docker service
#sed -i -E -e 's/localhost|0\.0\.0\.0/'"$CLUSTER_HOST"'/g' ${KUBECONFIG}
kind export kubeconfig --name $CLUSTER_NAME --internal


# docker logs $CLUSTER_HOST
# echo "=========================="
# cat drone/kind-config 
# echo "=========================="
# cat ${KUBECONFIG}

kubectl get po -A
kubectl wait node --all --for condition=ready
