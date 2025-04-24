#!/bin/bash

set -e

echo "Fetching Redis Enterprise DNS from Terraform outputs..."

echo "Installing Docker and Docker Compose..."
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

echo "Creating Prometheus configuration directory..."
mkdir prometheus

echo "Creating prometheus.yml with cluster DNS: $RS_CLUSTER_DNS"

cat > prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

  external_labels:
    monitor: "prometheus-stack-monitor"

scrape_configs:
  - job_name: prometheus
    scrape_interval: 10s
    scrape_timeout: 5s
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: redis-enterprise
    scrape_interval: 30s
    scrape_timeout: 30s
    metrics_path: /
    scheme: https
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets: ["${RS_CLUSTER_DNS}:8070"]
EOF

echo "Creating docker-compose.yml..."
cat > docker-compose.yml <<EOF
version: '3'

services:
  prometheus-server:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml


  grafana-ui:
      image: grafana/grafana
      ports:
          - 3000:3000
      environment:
         - GF_SECURITY_ADMIN_PASSWORD=secret
      links:
         - prometheus-server:prometheus
EOF

echo "Starting Prometheus and Grafana using Docker Compose..."
sudo docker-compose up -d

echo "Done!"
echo "Prometheus: http://<YOUR_VM_PUBLIC_IP>:9090"
echo "Grafana: http://<YOUR_VM_PUBLIC_IP>:3000 (login: admin / admin)"
echo "Metrics are scraped from: https://${RS_CLUSTER_DNS}:8070"
