resource "google_compute_instance" "worker" {
  count = 3
  name         = "worker-${count.index}"
  machine_type = "n1-standard-1"
  tags           = ["worker"]

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