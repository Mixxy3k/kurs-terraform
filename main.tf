terraform {
  # Definicja wymaganego dostawcy (provider) Docker!
  required_providers {
    docker = {
      source  = "kreuzwerker/docker" # Źródło dostawcy Terraform dla Dockera
      version = "~> 2.25"            # Wersja dostawcy Docker
    }
  }
}
# Ustawienie dostawcy Docker
provider "docker" {}

data "docker_network" "existing_network" {
  name = "app_network"
}

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
# Tworzenie kontenera dla MongoDB
resource "docker_container" "mongo" {
    name  = "mongo"
    image = docker_image.mongo.name

    ports {
        internal = 27017 # port w kontenerze
        external = 27017 # port w hoście 
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
}

# Tworzenie obrazu Dockera dla Nodejs
resource "docker_image" "app_image" {
    name = "node-mongo-app"
    build {
        context = "${path.module}/."
        dockerfile = "Dockerfile"
    }
}
# Tworzenie kontenera dla aplikacji Nodejs
# Tworzenie kontenera dla aplikacji Nodejs
resource "docker_container" "app" {
    name   = "app" # Nazwa kontenera
    image  = docker_image.app_image.name # Wykorzystanie obrazu lokalnego
    ports {
        internal = 3000 # port w kontenerze
        external = 3000 # port w hoście 
    }
    networks_advanced {
        name = docker_network.app_network.name
    }
    env = [
        "MONGO_HOST=mongo",
        "MONGO_PORT=27017"
    ]
    # Kontener aplikacji nie uruchomi się przed Mongo
    depends_on = [docker_container.mongo] 
}


