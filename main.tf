terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# Define the Docker network
resource "docker_network" "app_network" {
  name = "app-network"
}

# Define the NGINX container
resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx_server" {
  name  = "nginx-server"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8181
  }

  ports {
    internal = 443
    external = 443
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/build"
    container_path = "/usr/share/nginx/html"
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/localhost.crt"
    container_path = "/etc/nginx/ssl/localhost.crt"
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/localhost.key"
    container_path = "/etc/nginx/ssl/localhost.key"
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/nginx.conf"
    container_path = "/etc/nginx/conf.d/default.conf"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the MySQL Database container
resource "docker_image" "mysql" {
  name = "mysql:latest"
}

resource "docker_container" "mysql_db" {
  name  = "mysql-db"
  image = docker_image.mysql.image_id

  env = [
    "MYSQL_ROOT_PASSWORD=root_password",
    "MYSQL_DATABASE=react_app_db",
    "MYSQL_USER=app_user",
    "MYSQL_PASSWORD=app_password"
  ]

  ports {
    internal = 3306
    external = 8084
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/db-data"
    container_path = "/var/lib/mysql"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the phpMyAdmin container
resource "docker_image" "phpmyadmin" {
  name = "phpmyadmin/phpmyadmin:latest"
}

resource "docker_container" "phpmyadmin" {
  name  = "phpmyadmin"
  image = docker_image.phpmyadmin.image_id

  env = [
    "PMA_HOST=mysql-db",
    "PMA_USER=app_user",
    "PMA_PASSWORD=app_password"
  ]

  ports {
    internal = 80
    external = 8087
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the Backend API container
resource "docker_image" "node" {
  name = "node:16"
}

resource "docker_container" "express_backend" {
  name        = "express-backend"
  image       = docker_image.node.image_id
  working_dir = "/app"

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/backend"
    container_path = "/app"
  }

  ports {
    internal = 3001
    external = 8085
  }

  command = ["node", "index.js"]

  env = [
    "DB_HOST=mysql-db",
    "DB_USER=app_user",
    "DB_PASSWORD=app_password",
    "DB_NAME=react_app_db"
  ]

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the Prometheus container
resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_container" "prometheus" {
  name  = "prometheus"
  image = docker_image.prometheus.image_id

  ports {
    internal = 9090
    external = 8082
  }

  volumes {
    host_path      = "C:/Users/RON/Desktop/DevOps/DockerComposeTerraform/prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the Grafana container
resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_container" "grafana" {
  name  = "grafana"
  image = docker_image.grafana.image_id

  ports {
    internal = 3000
    external = 8083
  }

  networks_advanced {
    name = docker_network.app_network.name
  }
}

# Define the cAdvisor container
resource "docker_image" "cadvisor" {
  name = "gcr.io/cadvisor/cadvisor:latest"
}

resource "docker_container" "cadvisor" {
  name  = "cadvisor"
  image = docker_image.cadvisor.image_id

  ports {
    internal = 8080
    external = 8081
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker/"
    container_path = "/var/lib/docker"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/machine-id"
    container_path = "/etc/machine-id"
    read_only      = true
  }

  privileged = true

  command = ["--disable_metrics=disk"]

  networks_advanced {
    name = docker_network.app_network.name
  }
}