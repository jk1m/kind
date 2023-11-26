#!/bin/bash

printf "\n>>> Finish provisioning kind\n"

# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${REGISTRY_PORT_EXTERNAL} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${REGISTRY_PORT_EXTERNAL}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${REGISTRY_NAME}:5000"]
EOF
done

# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REGISTRY_PORT_EXTERNAL}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

printf "\n>>> Creating metallb (load balancer)\n"
kubectl apply -f $HOME/configs/metallb-manifest.yml

printf "\n>>> Sleeping for 60 seconds\n"
sleep 60

printf "\n>>> Finishing metallb creation\n"
kubectl apply -f $HOME/configs/metallb-config.yml

printf "\n>>> Deploy service example\n"
kubectl apply -f $HOME/configs/service-example.yml

printf "\n>>> Deploy Nginx ingress\n"
kubectl apply -f $HOME/configs/ingress-nginx.yml
