resource "google_compute_subnetwork" "public_subnet" {
  name          =  "${var.yourname}-${var.env}-pub-net"
  ip_cidr_range = var.rs_public_subnet
  network       = google_compute_network.vpc.id
  region        = var.region_name

  secondary_ip_range = [
    {
      range_name    = "gke-pods"
      ip_cidr_range = "192.168.10.0/24"
    },
    {
      range_name    = "gke-services"
      ip_cidr_range = "192.168.11.0/24"
    }
  ]
}
resource "google_compute_subnetwork" "private_subnet" {
  name          =  "${var.yourname}-${var.env}-pri-net"
  ip_cidr_range = var.rs_private_subnet
  network      = google_compute_network.vpc.id
  region        = var.region_name
}