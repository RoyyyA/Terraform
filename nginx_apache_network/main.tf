terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "2.20.2"
    }
  }
}

provider "docker" {
#  host = "unix:///var/run/docker.sock"
  }

resource "docker_network" "network" {
  name   = "my_network"
  driver = "bridge"
  ipam_config {
    subnet = "10.0.2.0/24"
    gateway = "10.0.2.1"
  }
}

# resource "docker_image" "ubuntu" {
#   name = "ubuntu:latest"
#   keep_locally = false
# }

resource "docker_image" "nginx" {   
  name = "nginx:latest"
  keep_locally = false
  
}

resource "docker_image" "httpd" {   
  name = "httpd:latest"
  keep_locally = false
  
}

resource "docker_container" "ubuntu" {
  image = docker_image.ubuntu.latest
  name  = "test_ubuntu"
  networks_advanced {
    name = "docker_network.network.my_network"
    ipv4_address = "10.0.2.10"
  }
  ports {
    internal = 80
    external = 8000
  }

  provisioner "local-exec" {
    command = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  
  }
}
resource "docker_container" "nginx" {
  image = docker_image.nginx.latest
  name = "test_nginx"
  networks_advanced {
    name = "docker_network.network.my_network"
    ipv4_address = "10.0.2.11"
  }
  ports {
    internal = 8001
    external = 8081
  }
}


resource "docker_container" "httpd" {
  image = docker_image.httpd.latest
  name = "test_apache"
  networks_advanced {
    name = "docker_network.network.my_network"
    ipv4_address = "10.0.2.12"
  }
  ports {
    internal = 8080
  }

}


output "nginx_container_ID" {
  description = "ID of nginx container"
  value = docker_container.nginx.id
  
}

output "apache_container_ID" {
  description = "ID of apache container"
  value = docker_container.httpd.id
  
}
