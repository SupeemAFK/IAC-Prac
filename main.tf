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
    count = 5
    image = docker_image.nginx.image_id
    name  = "my-server-${count.index}"
    ports {
        internal = 80
        external = 8000 + count.index
    }
}

resource "local_file" "create_ansible_inventory" {
  
  # This creates a multi-line string and loops through our containers
  content = <<-EOT
  [webservers]
  %{ for container in docker_container.nginx ~}
  ${container.name} ansible_connection=docker
  %{ endfor ~}
  EOT
  
  # This tells Terraform what to name the file it creates
  filename = "${path.module}/inventory.ini"
}

resource "null_resource" "run_ansible" {
  
  # Now it waits for the containers AND the inventory file!
  depends_on = [
    docker_container.nginx, 
    local_file.create_ansible_inventory
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini playbook.yml"
  }
}