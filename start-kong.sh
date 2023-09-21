#!/bin/bash

# Note: local registry creation, KinD, and kong provisioning
# have been combined into one
#
# See:
# https://kind.sigs.k8s.io/docs/user/local-registry/

# 1. Create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  printf "\n>>> Creating local registry\n"
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi

printf "\n>>> Pulling kindest/node:v${KUBECTL_VER}\n"
docker pull kindest/node:v${KUBECTL_VER}

# 2. Create kind cluster with containerd registry config dir enabled
# TODO: kind will eventually enable this by default and this patch will
# be unnecessary.
#
# See:
# https://github.com/kubernetes-sigs/kind/issues/2875
# https://github.com/containerd/containerd/blob/main/docs/cri/config.md#registry-configuration
# See: https://github.com/containerd/containerd/blob/main/docs/hosts.md
#
# Note: containerd registry config dir has already been configured in configs/kind.yml
printf "\n>>> Creating KinD cluster with local registry\n"
kind create cluster --config configs/kind-kong.yml --image kindest/node:v${KUBECTL_VER} --name kind

# 3. Add the registry config to the nodes
#
# This is necessary because localhost resolves to loopback addresses that are
# network-namespace local.
# In other words: localhost in the container is not localhost on the host.
#
# We want a consistent name that works from both ends, so we tell containerd to
# alias localhost:${reg_port} to the registry container when pulling images
REGISTRY_DIR="/etc/containerd/certs.d/localhost:${reg_port}"
for node in $(kind get nodes); do
  docker exec "${node}" mkdir -p "${REGISTRY_DIR}"
  cat <<EOF | docker exec -i "${node}" cp /dev/stdin "${REGISTRY_DIR}/hosts.toml"
[host."http://${reg_name}:5000"]
EOF
done

# 4. Connect the registry to the cluster network if not already connected
# This allows kind to bootstrap the network but ensures they're on the same network
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# 5. Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

printf "\n>>> Creating metallb (load balancer)\n"
kubectl apply -f configs/metallb-manifest.yml

printf "\n>>> Sleeping for 60 seconds\n"
sleep 60

printf "\n>>> Finishing metallb creation\n"
kubectl apply -f configs/metallb-config.yml

printf "\n>>> Provisioning kong\n"
kubectl create namespace kong

kubectl create secret generic kong-config-secret -n kong \
    --from-literal=portal_session_conf='{"storage":"kong","secret":"super_secret_salt_string","cookie_name":"portal_session","cookie_same_site":"Lax","cookie_secure":false}' \
    --from-literal=admin_gui_session_conf='{"storage":"kong","secret":"super_secret_salt_string","cookie_name":"admin_session","cookie_same_site":"Lax","cookie_secure":false}' \
    --from-literal=pg_host="enterprise-postgresql.kong.svc.cluster.local" \
    --from-literal=kong_admin_password=kong \
    --from-literal=password=kong

kubectl create secret generic kong-enterprise-license --from-literal=license="'{}'" -n kong --dry-run=client -o yaml | kubectl apply -f -

helm repo add jetstack https://charts.jetstack.io ; helm repo update

helm upgrade --install cert-manager jetstack/cert-manager --version v${HELM_CERT_MANAGER_VER} \
    --set installCRDs=true --namespace cert-manager --create-namespace

bash -c "cat <<EOF | kubectl apply -n kong -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: quickstart-kong-selfsigned-issuer-root
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: quickstart-kong-selfsigned-issuer-ca
spec:
  commonName: quickstart-kong-selfsigned-issuer-ca
  duration: 8640h0m0s
  isCA: true
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: quickstart-kong-selfsigned-issuer-root
  privateKey:
    algorithm: ECDSA
    size: 256
  renewBefore: 720h0m0s
  secretName: quickstart-kong-selfsigned-issuer-ca
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: quickstart-kong-selfsigned-issuer
spec:
  ca:
    secretName: quickstart-kong-selfsigned-issuer-ca
EOF"

helm repo add kong https://charts.konghq.com ; helm repo update

helm upgrade --install quickstart kong/kong --version ${HELM_KONG_QUICKSTART_VER} --namespace kong --values https://bit.ly/KongGatewayHelmValuesAIO
