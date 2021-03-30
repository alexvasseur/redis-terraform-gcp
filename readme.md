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

```
terraform destroy
```


## Memtier

See memtier.sh for a basic example



# Other articles

https://github.com/radeksimko/terraform-examples/tree/master/google-consul

https://medium.com/slalom-technology/a-complete-gcp-environment-with-terraform-c087190366f0

https://gist.github.com/smford22/54aa5e96701430f1bb0ea6e1a502d23a

