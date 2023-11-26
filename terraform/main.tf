resource "docker_image" "kind_node" {
  name = "kindest/node:v1.28.0"
  force_remove = true
}

resource "kind_cluster" "this" {
  name            = var.kind_cluster_name
  node_image      = var.kind_image
  kubeconfig_path = pathexpand("~/.kube/config")
  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    containerd_config_patches = [
      <<-TOML
      [plugins."io.containerd.grpc.v1.cri".registry]
        config_path = "/etc/containerd/certs.d"
      TOML
    ]

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }
  }
}

resource "docker_image" "registry" {
  name = "registry:2.8.3"
}

resource "docker_container" "registry" {
  image             = docker_image.registry.image_id
  name              = "kind-registry"
  network_mode      = "bridge"
  privileged        = false
  publish_all_ports = false
  read_only         = false
  restart           = "always"
  rm                = false

  ports {
    external = 5001
    internal = 5000
    ip       = "127.0.0.1"
    protocol = "tcp"
  }

  networks_advanced {
    name = "kind"
  }
}
