# Redis Enterprise - Terraforming on GCP

## About

<img width=150
    src="https://redislabs.com/wp-content/themes/wpx/assets/images/logo-redis.svg"
    alt="Read more about Redis Enterprise" />
- Docs https://docs.redislabs.com/latest/rs/
- Provided by Redis Labs - https://redislabs.com/redis-enterprise-software/overview/


## Assumption

- gcloud ssh working with `~/.ssh/google_compute_engine` private key
- GCP IAM / service account exist, with `Compute Admin` and `DNS Administrator` roles
- GCP IAM service account exported `json` in current folder
- terraform

## Setup

- `terraform init`
- (optional) use a `terraform.tfvars` to override variable like those two important one or those that have no default:
```
yourname="testingthis"
credentials="GCP IAM key file.json"
```
- review `variable.tf` to learn what you can override in your `terraform.tfvars`
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

admin = "admin@redis.io"
ips = [
  "35.205.232.197",
  "35.233.84.153",
]
password = "xxxxx"
rs_cluster_dns = "cluster.<yourname>.demo.redislabs.com"
rs_ui = "https://35.205.232.197:8443"
rs_ui_dns = "https://cluster.<yourname>.demo.redislabs.com:8443"
```

```
terraform destroy
```

## Stoping & restarting nodes

If you stop the VM and need to restart them:
- you should restart the VM with GCP (Terraform will not do that for you)
- the startup-script will re-run, ignore RS as it is already installed, but update RS node external_addr if the IP changed
Then:
- you must then use `terraform plan` and ``terraform apply` as you external IP addr may have changed. This will update them in the DNS (this may take time for DNS to propagate, ~5min).
- in the meantime you can connect to node1 with the external_addr on https port 8443


## Command line

Use `gcloud` with your machine node name that looks like:
```
gcloud compute ssh <yourname>-dev-1
```
You can explore logs in `/home/ubuntu` and in `/var/log/syslog` for the startup-script.

## Memtier

see `memtier.sh` for a very basic example

## Redis Enterprise

![Nodes, shards and clusters and Redis databases](https://redislabs.com/wp-content/uploads/2019/06/blog-volkov-20190625-1-v5.png)

## Known Issues

- if you stopped the VM in GCP, Terraform will assume their external IP are void and will clean up the DNS but will not restart the VM

## Todos

- Configure for multi AZ and rack awareness


# Other articles

https://github.com/radeksimko/terraform-examples/tree/master/google-consul

https://medium.com/slalom-technology/a-complete-gcp-environment-with-terraform-c087190366f0

https://gist.github.com/smford22/54aa5e96701430f1bb0ea6e1a502d23a

