resource "google_compute_instance" "node1" {
  name         = "${var.yourname}-${var.env}-1"
  machine_type = "e2-standard-2" // https://gcpinstances.info/?cost_duration=monthly
  // example with minimal 2vcpu 4GB RAM
  // which leaves about 1.4GB for Redis DB
  // machine_type = "custom-2-4096" // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
    }
  }
  labels = {
    owner = var.yourname
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/instance.sh", {
      cluster_dns = "cluster.${var.yourname}.${var.dns_zone_dns_name}",
      node_id  = 1
      node_1_ip   = ""
      RS_release = var.RS_release
      RS_admin = var.RS_admin
      RS_password = random_password.password.result
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "nodeX" {
  count = var.clustersize - 1

  name         = "${var.yourname}-${var.env}-${count.index + 1 + 1}" #+1+1 as we have node1 above
  machine_type = "e2-standard-2"
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
    }
  }
  labels = {
    owner = var.yourname
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/instance.sh", {
      cluster_dns = "cluster.${var.yourname}.${var.dns_zone_dns_name}",
      node_id  = count.index+1+1
      node_1_ip = google_compute_instance.node1.network_interface.0.network_ip
      RS_release = var.RS_release
      RS_admin = var.RS_admin
      RS_password = random_password.password.result
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_dns_record_set" "node1" {
  name = "node1.${var.yourname}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.node1.network_interface.0.access_config.0.nat_ip]
}
resource "google_dns_record_set" "nodeX" {
  count = var.clustersize - 1

  name = "node${count.index + 1 + 1}.${var.yourname}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.nodeX[count.index].network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "name_servers" {
  name = "cluster.${var.yourname}.${var.dns_zone_dns_name}."
  type = "NS"
  ttl  = 60
  managed_zone = var.dns_managed_zone

  rrdatas = flatten([local.n1, flatten(local.nX)])
}

locals {
  n1 = google_dns_record_set.node1.name
  nX = [for xx in google_dns_record_set.nodeX : xx.name]
} 

resource "random_password" "password" {
  length           = 12
  special          = true
  override_special = "_"
}
