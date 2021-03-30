provider "google" {
  project     = var.project
  credentials = var.credentials
}
######################################################################
output "rs_ui_dns" {
	value = "https://node1.${var.yourname}.${var.dns_zone_dns_name}:8443"
}
output "rs_ui" {
	value = "https://${google_compute_instance.node1.network_interface.0.access_config.0.nat_ip}:8443"
}
output "rs_cluster_dns" {
	value = "cluster.${var.yourname}.${var.dns_zone_dns_name}"
}
output "ips" {
  value = flatten([google_compute_instance.node1.network_interface.0.access_config.0.nat_ip , flatten([google_compute_instance.nodeX.*.network_interface.0.access_config.0.nat_ip])])
}
output "admin" {
  value = var.RS_admin
}
output "password" {
  value = random_password.password.result
}
