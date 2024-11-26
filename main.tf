terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.25"
    }
  }
}

# Ustawienie dostawcy Docker
provider "docker" {}

# Pobranie informacji o istniejącej sieci
data "docker_network" "existing_network" {
  name = "app_network"
}

# Utworzenie sieci dla aplikacji jeśli nie istnieje
resource "docker_network" "app_network" {
  count = length(data.docker_network.existing_network.id) > 0 ? 0 : 1
  name  = "app_network"
}

# Wolumin dla MongoDB
resource "docker_volume" "mongo_data" {
  name = "mongo_data"
}

# Pobranie obrazu z DockerHub
resource "docker_image" "mongo" {
  name = "mongo:5.0"
}

# Tworzenie kontenera dla MongoDB
resource "docker_container" "mongo" {
  name  = "mongo"
  image = docker_image.mongo.name

  ports {
    internal = 27017
    external = 27017
  }

  networks_advanced {
    name = length(docker_network.app_network) > 0 ? docker_network.app_network[0].name : data.docker_network.existing_network.name
  }

  mounts {
    target = "/data/db"
    source = docker_volume.mongo_data.name
    type   = "volume"
  }

  healthcheck {
    test     = ["CMD", "mongo", "--eval", "db.runCommand({ ping: 1 })"]
    interval = "10s"
    retries  = 3
  }
}

# Tworzenie obrazu Dockera dla Nodejs
resource "docker_image" "app_image" {
  name = "node-mongo-app"
  build {
    context    = "${path.module}/."
    dockerfile = "Dockerfile"
  }
}

# Tworzenie kontenera dla aplikacji Nodejs
resource "docker_container" "app" {
  name   = "app"
  image  = docker_image.app_image.name

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = length(docker_network.app_network) > 0 ? docker_network.app_network[0].name : data.docker_network.existing_network.name
  }

  env = [
    "MONGO_HOST=mongo",
    "MONGO_PORT=27017"
  ]

  depends_on = [docker_container.mongo]
}
