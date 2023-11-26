terraform {
  required_version = "1.6.4"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    kind = {
      source  = "tehcyx/kind"
      version = "0.2.1"
    }
  }
}
