resource "google_compute_instance" "master" {
  count = 1
  name         = "master-${count.index}"
  machine_type = "n1-standard-2"
  tags           = ["master"]

  metadata = {
    ssh-keys = "${var.user}:${file(var.public_key_path)}"
  }

  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}