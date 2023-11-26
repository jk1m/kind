variable "registry_image" {
  type    = string
  default = "registry:2.8.3"
}

variable "kind_image" {
  type    = string
  default = "kindest/node:v1.28.0"
}

variable "kind_cluster_name" {
  type = string
  default = "kind"
} 
