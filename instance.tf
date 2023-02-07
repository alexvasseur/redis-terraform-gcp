resource "google_compute_instance" "app" {
  count = var.app_enabled ? 1 : 0

  name         = "${var.yourname}-${var.env}-app"
  machine_type = "n2-highcpu-16" // for memtier/TLS we need a highcpu machine
  //machine_type = var.machine_type
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
      size = 30 //GB
    }
  }
  labels = {
    owner = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/app.sh", {
      cluster_dns_suffix = "${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
      nodes  = "${var.clustersize}"
    })
  }
  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance" "node1" {
  name         = "${var.yourname}-${var.env}-1"
  machine_type = var.machine_type
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
      size = 30 //GB
    }
  }
  // Redis on Flash with actual infrastructure SSD local disk for NVMe
  dynamic "scratch_disk" {
    // if enabled, there will be 2 SSD mounted as RAID-0 array
    for_each = var.rof_nvme_enabled ? [1,2] : []
    content {
        interface = "NVME"
        //default size is 375 GB or function of instance type
    }
  }
  labels = {
    owner = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/instance.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
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
  machine_type = var.machine_type
  zone         = "${var.region_name}-b" //TODO
  tags         = ["ssh", "http"]
  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-1804-lts"
      size = 30 // GB
    }
  }
  // Redis on Flash with actual infrastructure SSD local disk for NVMe
  dynamic "scratch_disk" {
    // if enabled, there will be 2 SSD mounted as RAID-0 array
    for_each = var.rof_nvme_enabled ? [1,2] : []
    content {
        interface = "NVME"
        //default size is 375 GB or function of instance type
    }
  }
  labels = {
    owner = var.yourname
    skip_deletion = "yes"
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/google_compute_engine.pub")}"
    startup-script = templatefile("${path.module}/scripts/instance.sh", {
      cluster_dns = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}",
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

resource "google_dns_record_set" "app" {
  count = var.app_enabled ? 1 : 0

  name = "app.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.app.0.network_interface.0.access_config.0.nat_ip]
}
resource "google_dns_record_set" "node1" {
  name = "node1.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.node1.network_interface.0.access_config.0.nat_ip]
}
resource "google_dns_record_set" "nodeX" {
  count = var.clustersize - 1

  name = "node${count.index + 1 + 1}.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
  type = "A"
  ttl  = 300
  managed_zone = var.dns_managed_zone

  rrdatas = [google_compute_instance.nodeX[count.index].network_interface.0.access_config.0.nat_ip]
}

resource "google_dns_record_set" "name_servers" {
  name = "cluster.${var.yourname}-${var.env}.${var.dns_zone_dns_name}."
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
