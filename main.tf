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

# Utworzenie sieci dla aplikacji (bez warunku na istnienie)
resource "docker_network" "app_network" {
  name = "app_network"

  lifecycle {
    ignore_changes = [name] # Ignore changes if the network already exists
  }
}

# Wolumin dla MongoDB
resource "docker_volume" "mongo_data" {
  name = "mongo_data"

  lifecycle {
    ignore_changes = [name] # Ignore changes if the volume already exists
  }
}

# Pobranie obrazu z DockerHub
resource "docker_image" "mongo" {
  name = "mongo:5.0"

  lifecycle {
    ignore_changes = [name] # Ignore changes for existing images
  }
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
    name = docker_network.app_network.name
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

  lifecycle {
    ignore_changes = [name, ports, networks_advanced, mounts, healthcheck]
  }
}

# Tworzenie obrazu Dockera dla Nodejs
resource "docker_image" "app_image" {
  name = "node-mongo-app"
  build {
    context    = "${path.module}/."
    dockerfile = "Dockerfile"
  }

  lifecycle {
    ignore_changes = [name] # Prevent recreation of the image if it exists
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
    name = docker_network.app_network.name
  }

  env = [
    "MONGO_HOST=mongo",
    "MONGO_PORT=27017"
  ]

  depends_on = [docker_container.mongo]

  lifecycle {
    ignore_changes = [name, ports, networks_advanced, env]
  }
}
