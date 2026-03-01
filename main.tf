terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "my-first-server"
  ports {
    internal = 80
    external = 8000
  }
}

resource "null_resource" "run_ansible" {
  # Wait for the container to exist before trying to run Ansible!
  depends_on = [docker_container.nginx]

  provisioner "local-exec" {
    # This is the exact command you were typing manually
    command = "ansible-playbook -i inventory.ini playbook.yml"
  }
}