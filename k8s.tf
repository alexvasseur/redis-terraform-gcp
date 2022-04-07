# see https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest
#
# terraform init -upgrade


data "google_client_config" "default" {}

#provider "kubernetes" {
#  host                   = "https://${module.gke.endpoint}"
#  token                  = data.google_client_config.default.access_token
#  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
#}

#module "gke" {
#  source                 = "terraform-google-modules/kubernetes-engine/google"
#  project_id             = var.project
#
#   name                   = "${var.yourname}-${var.env}-gke"
#   regional               = true
#   region                 = var.region_name
#   network                = google_compute_network.vpc.name
#   subnetwork             = google_compute_subnetwork.public_subnet.name
#   ip_range_pods          = "gke-pods"
#   ip_range_services      = "gke-services"
#   create_service_account = false
#   service_account        = "avasseur@central-beach-194106.iam.gserviceaccount.com"
#   #skip_provisioners      = var.skip_provisioners

#   # skip default node pool so keep it at minimum and remove (per docs)
#   remove_default_node_pool = true
#   initial_node_count       = 1
# }

resource "google_container_cluster" "gke-cluster" {
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
  name       = "redis-node-pool"
  cluster    = google_container_cluster.gke-cluster.name
  node_count = var.gke_clustersize
  node_config {
    machine_type = var.gke_machine_type
  }
}

output "kubectl" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.gke-cluster.name}"
}