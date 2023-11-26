ARG BASE_VER=24.0.2-dind
FROM docker:${BASE_VER}

ARG KIND_VER=0.20.0
ARG KUBECTL_VER=1.28.0
ARG HELM_VER=3.12.2
ARG TF_VER=1.6.4
ARG DECK_VER=1.25.0
ARG YQ_VER=4.35.1
ARG ISTIO_VER=1.20.0
ARG REGISTRY_NAME=kind-registry
ARG REGISTRY_VER=2.8.3
ARG REGISTRY_PORT_EXTERNAL=5001

# "export" these vars for use in scripts
ENV KUBECTL_VER=${KUBECTL_VER}
ENV REGISTRY_NAME=${REGISTRY_NAME}
ENV REGISTRY_VER=${REGISTRY_VER}
ENV REGISTRY_PORT_EXTERNAL=${REGISTRY_PORT_EXTERNAL}

RUN apk add curl bash jq httpie gettext coreutils vim git && \
  curl -sLo ./kind https://kind.sigs.k8s.io/dl/v${KIND_VER}/kind-linux-amd64 && \
  chmod +x kind && \
  mv kind /usr/local/bin/kind && \
  curl -sLo ./kubectl https://dl.k8s.io/release/v${KUBECTL_VER}/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl && \
  curl -sLo ./helm.tar.gz https://get.helm.sh/helm-v${HELM_VER}-linux-amd64.tar.gz && \
  tar -xf helm.tar.gz && \
  mv linux-amd64/helm /usr/local/bin/helm && \
  chown root:root /usr/local/bin/helm && \
  rm -f helm.tar.gz && \
  rm -fr linux-amd64 && \
  curl -sLo tf.zip https://releases.hashicorp.com/terraform/${TF_VER}/terraform_${TF_VER}_linux_amd64.zip && \
  unzip tf.zip && \
  rm -f tf.zip && \
  mv terraform /usr/local/bin/terraform && \
  curl -sLo deck.tar.gz https://github.com/kong/deck/releases/download/v${DECK_VER}/deck_${DECK_VER}_linux_amd64.tar.gz && \
  tar -xf deck.tar.gz && \
  rm -f deck.tar.gz && \
  chown root:root deck && \
  mv deck /usr/local/bin/deck && \
  curl -sLo yq https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_amd64 && \
  chmod +x yq && \
  mv yq /usr/local/bin/yq && \
  curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VER} sh - && \
  mv istio-${ISTIO_VER}/bin/istioctl /usr/local/bin/istioctl

WORKDIR /root

COPY README.md KIND.md KONG.md start-kind.sh start-kong.sh delete.sh .
COPY configs/ ./configs
COPY examples/ ./examples
COPY terraform/ ./terraform

RUN echo 'alias deck="deck --kong-addr https://kong.127-0-0-1.nip.io/api --tls-skip-verify"' >> ~/.bashrc && \
  echo 'alias ..="cd ../"' >> ~/.bashrc && \
  source ~/.bashrc

EXPOSE 80 443
