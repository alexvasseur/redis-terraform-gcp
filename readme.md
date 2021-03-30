# Redis Enterprise - Terraforming on GCP

## Assumption

- gcloud ssh working with `~/.ssh/google_compute_engine` private key
- GCP IAM / service account exist, with `Compute Admin` and `DNS Administrator` roles
- GCP IAM service account exported `json` in current folder
- terraform

## Setup

- `terraform init`
- see `variable.tf`
    - configure number of nodes and admin email
    - review/change as needed
    - configure the name of the json credentials file if needed

## Usage

```
terraform plan
terraform apply
```
will setup GCP, VPC, networks/firewall, DNS for Redis Enterprise
- node1 will be cluster master
- node2.. will be joining the cluster
- output will show Redis Enterprise cluster ui url and other info
- an admin password will be auto generated
The nodes and cluster are created using external addr and DNS.

Example of a 2 nodes setup
```
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

Outputs:

ips = [
  "35.205.232.197",
  "35.233.84.153",
]
password = "xxxxx"
rs_cluster_dns = "cluster.avasseur.demo.redislabs.com"
rs_ui = "https://35.205.232.197:8443"
rs_ui_dns = "https://node1.avasseur.demo.redislabs.com:8443"
```

```
terraform destroy
```

## Memtier

see `memtier.sh` for a very basic example

## Todos

Configure for multi AZ and rack awareness




# Other articles

https://github.com/radeksimko/terraform-examples/tree/master/google-consul

https://medium.com/slalom-technology/a-complete-gcp-environment-with-terraform-c087190366f0

https://gist.github.com/smford22/54aa5e96701430f1bb0ea6e1a502d23a

