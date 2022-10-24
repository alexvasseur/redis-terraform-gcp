# The GKE cluster will only be created if gke_enabled = true (default: false)
#
# Using the core Terraform construct for simple GKE
# and not the Google provided alternative at https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest
#
# terraform init -upgrade
# might be required if you start using this file for first time from an existing install

data "google_client_config" "default" {}

resource "google_container_cluster" "gke-cluster" {
  count = var.gke_enabled ? 1 : 0

  name                   = "${var.yourname}-${var.env}-gke"
  location               = "${var.region_name}-b" # single zone cluster
  network                = google_compute_network.vpc.name
  subnetwork             = google_compute_subnetwork.public_subnet.name

  # skip default node pool so keep it at minimum and remove (per docs)
  remove_default_node_pool = true
  initial_node_count       = 1

  maintenance_policy {
    daily_maintenance_window {
      start_time = "01:00"
    }
  }  
}


resource "google_container_node_pool" "np" {
  count = var.gke_enabled ? 1 : 0

  name       = "redis-node-pool"
  cluster    = google_container_cluster.gke-cluster.0.name
  node_count = var.gke_clustersize
  node_config {
    machine_type = var.gke_machine_type
    labels = {
      owner = var.yourname
      skip_deletion = "yes"
    }
  }
}

output "how_to_kubectl" {
  value = var.gke_enabled ? "gcloud container clusters get-credentials ${google_container_cluster.gke-cluster.0.name}" : ""
}