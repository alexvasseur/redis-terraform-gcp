// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !! PLEASE CHANGE in a terraform.tfvars
// yourname="...."
// credentials="GCP IAM service account key file.json"
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
variable "yourname" {
  # No default
  # Use CLI or interactive input. It is best to setup your own terraform.tfvars
}
variable "credentials" {
  default = "central-beach-194106-fda731676157.json"
}
// other optional edits *************************************
variable "clustersize" {
  # You should use 3 for some more realistic installation
  default = "3"
}




// other possible edits *************************************
variable "RS_release" {
  default = "https://s3.amazonaws.com/redis-enterprise-software-downloads/7.4.2/redislabs-7.4.2-54-focal-amd64.tar"
  #default = "https://s3.amazonaws.com/redis-enterprise-software-downloads/7.2.4/redislabs-7.2.4-92-focal-amd64.tar"
  #default = "https://s3.amazonaws.com/redis-enterprise-software-downloads/6.4.2/redislabs-6.4.2-81-focal-amd64.tar"
  #"https://s3.amazonaws.com/redis-enterprise-software-downloads/6.2.18/redislabs-6.2.18-65-bionic-amd64.tar"
}
variable "project" {
  default = "central-beach-194106"
}
variable "machine_type" {
  default = "e2-standard-2" // 2 vCPU 8GB
  // https://gcpinstances.info/?cost_duration=monthly
  // example with minimal 2vcpu 4GB RAM
  // which leaves about 1.4GB for Redis DB
  // machine_type = "custom-2-4096" // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance
  // other machines of interest:
  //
  // e2-highmem-8   // 8 vCPU 64 GB
  // n2-highcpu-16  // 16 vCPU 32 GB
}
// machine name will be "<yourname>-<env>-node1"
// use "default" ie same as default "terraform workspace"
variable "env" {
  default = "default"
}
variable "RS_admin" {
  default = "admin@redis.io"
}
variable "region_name" {
  default = "europe-west1"
}
// Redis on Flash flag to fully create SSD NVMe disk and not only enable Flash in cluster configuration
variable "rof_nvme_enabled" {
  default = false
}


// other possible edits ************************************* client machine
// client machine with memtier is optional
variable "app_enabled" {
  default = false
}

// other possible edits ************************************* Kubernetes KGE
// GKE K8s is optional
variable "gke_enabled" {
  default = false
}
// GKE K8s is optional so node pool will default to 0 nodes
variable "gke_clustersize" {
  default = 0
}
// e2-standard-8 will work by default
// e2-standard-4 (4 vCPU) requires Redis Enterprise REC yaml to be fine tuned
// as default request is 2 CPU per REC pod, and with other K8s services running on GKE
// as well as the CRD this will fail on a single node K8s GKE cluster
variable "gke_machine_type" {
  default = "e2-standard-8" # 8 vCPU, 32 GB
}


// other possible edits ************************************* networking

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
