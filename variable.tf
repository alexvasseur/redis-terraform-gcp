// mandatory edits *************************************
variable "project" {
  default = "central-beach-194106"
}
variable "credentials" {
  default = "central-beach-194106-fda731676157.json"
}
// machine name will be "<yourname>-<env>-node1"
variable "env" {
  default = "dev"
}
// will be used as GCP naming prefix for machines, DNS zones, etc.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !! PLEASE CHANGE
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!
variable "yourname" {
  # No default
  # Use CLI or interactive input. It is best to setup your own terraforms.tfvars
}
variable "RS_admin" {
  default = "admin@redis.io"
}
variable "clustersize" {
  # You should use 3 for some more realistic installation
  default = "2"
}
variable "region_name" {
  default = "europe-west1"
}
// must be a zone that already exist - we will not create it but will add to it
variable "dns_managed_zone" {
  default = "demo-clusters"
}
// RS DNS and cluster will be
// cluster.<yourname>.demo.redislabs.com
// node1.<yourname>.demo.redislabs.com
// ......<yourname>.demo.redislabs.com
// node3.<yourname>.demo.redislabs.com
variable "dns_zone_dns_name" {
  default = "demo.redislabs.com"
}
// optional edits *************************************
variable "rs_private_subnet" {
  default = "10.26.1.0/24"
}
variable "rs_public_subnet" {
  default = "10.26.2.0/24"
}
