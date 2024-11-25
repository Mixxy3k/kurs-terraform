terraform {
  # Definicja wymaganego dostawcy (provider) Docker
  required_providers {
    docker = {
      source  = "kreuzwerker/docker" # Źródło dostawcy Terraform dla Dockera
      version = "~> 2.25"            # Wersja dostawcy Docker
    }
  }
}

provider "docker" {
}

resource "docker_network" "app_network" {
  name = "app_network"
}

resource "docker_volume" "mongo_data" {
  name = "mongo_data"
}

resource "docker_image" "mongo" {
  name         = "mongo"
  pull_triggers = ["docker_network.app_network"]
}

resource "docker_container" "mongo" {
  name  = "mongo"
  image = docker_image.mongo.latest
  ports {
    internal = 27017
    external = 27017
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  mounts {
    type        = "volume"
    source      = docker_volume.mongo_data.name
    target      = "/data/db"
    read_only   = false
    propagation = "rprivate"
  }
}

resource "docker_image" "app_image" {
  name         = "node-mongo-app"
  build {
    context = "./app"
  }
}

resource "docker_container" "app" {
  name  = "app"
  image = docker_image.app_image.latest
  ports {
    internal = 3000
    external = 3000
  }
  networks_advanced {
    name = docker_network.app_network.name
  }
  depends_on = [docker_container.mongo]
}

output "app_ip" {
  value = "http://localhost:3000"
  description = "Adres aplikacji"
}