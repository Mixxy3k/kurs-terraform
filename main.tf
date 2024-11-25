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

# Sieć do komunikacji pomiędzy kontenerami
resource "docker_network" "app_network" {
    name = "app_network"
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
    name = "mongo"
    image = docker_image.mongo.name

    ports {
        internal = 27017 # port w kontenerze
        external = 27017 # port w hoście 
    }
    # Podłączenie do sieci 
    networks_advanced {
        name = docker_network.app_network.name
    }
    # Montowanie woluminu MongoDB
    mounts {
        target = "/data/db"
        source = docker_volume.mongo_data.name
        type = "volume"
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
resource "docker_container" "app" {
    name = "app" # Nazwa kontenera
    # image = docker_image.app_image.name # Wykorzystanie obrazu z DockerHub
    image = "${var.docker_image}"

    ports {
        internal = 3000 # port w kontenerze
        external = 3000 # port w hoście 
    }
    networks_advanced {
        name = docker_network.app_network.name
    }
    # Kontener aplikacji nie uruchomi się przed Mongo
    depends_on = [docker_container.mongo] 
}


