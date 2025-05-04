provider "google" {
  #credentials = file(var.credentials) Use this or you can also use environment variables
  project = var.project_id
  region  = var.region
}

# GCS bucket for data lake with versioning
resource "google_storage_bucket" "data_lake" {
  name          = "${var.project_id}-datalake"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }
}


# BigQuery dataset
resource "google_bigquery_dataset" "topterms_dataset" {
  dataset_id    = "topterms_analysis"
  friendly_name = "Google Trends"
  description   = "Dataset for Analysis of Top International trending Terms for helping businesses"
  location      = var.region
}

# Service account
resource "google_service_account" "pipeline_service_account" {
  account_id   = var.service_id
  display_name = "Trends Pipeline Service Account"
}

# IAM bindings for BigQuery
resource "google_project_iam_binding" "bigquery_admin" {
  project = var.project_id
  role    = "roles/bigquery.admin"
  members = [
    "serviceAccount:${google_service_account.pipeline_service_account.email}",
  ]
}

# IAM bindings for GCS
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.pipeline_service_account.email}",
  ]
}

# Upload Kestra workflow to GCS
resource "google_storage_bucket_object" "kestra_workflow" {
  name    = "workflows/trends_ingest.yml"
  bucket  = google_storage_bucket.kestra_storage.name

  content = <<EOF
id: trends_ingest
namespace: Topterms
description: |
  Extracts startup data from the public BigQuery dataset, 
  processes it, and loads it into our optimized table structure

tasks:
  - id: extract_data
    type: io.kestra.plugin.gcp.bigquery.Query
    sql: |
      SELECT * 
      FROM  \`bigquery-public-data.google_trends.international_top_terms\`
      WHERE refresh_date = "2025-04-29"
      LIMIT 1000

    destinationTable: "{{gcp.project}}.topterms_dataset.Top_Terms_raw"
    serviceAccount: "{{gcp.serviceAccount}}"
EOF

  depends_on = [google_storage_bucket.kestra_storage]
}

# Outputs
output "gcs_bucket" {
  value = google_storage_bucket.data_lake.name
}

output "kestra_storage_bucket" {
  value = google_storage_bucket.kestra_storage.name
}

output "service_account" {
  value = google_service_account.pipeline_service_account.email
}

output "gke_cluster" {
  value = google_container_cluster.kestra_cluster.name
}

output "gke_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.kestra_cluster.name} --region ${var.region} --project ${var.project_id}"
}

output "kestra_install_commands" {
  value = <<EOT
# Get cluster credentials
gcloud container clusters get-credentials ${google_container_cluster.kestra_cluster.name} --region ${var.region} --project ${var.project_id}

# Install Kestra using Helm
helm repo add kestra https://kestra-io.github.io/helm-charts
helm repo update
helm install kestra kestra/kestra \\
  --set env.config.kestra.storage.type=gcs \\
  --set env.config.kestra.storage.gcs.bucket=${google_storage_bucket.kestra_storage.name} \\
  --set env.config.kestra.variables.gcp.project=${var.project_id} \\
  --set env.config.kestra.variables.gcp.serviceAccount=${google_service_account.pipeline_service_account.email}

# Expose the UI
kubectl expose deployment kestra --type=LoadBalancer --name=kestra-ui --port=8080

# Wait for external IP
kubectl get service kestra-ui

# Import the workflow
export KESTRA_URL=$(kubectl get service kestra-ui -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8080
curl -X POST "http://$KESTRA_URL/api/v1/flows/import" -H "Content-Type: application/yaml" --data-binary @<(gsutil cat gs://${google_storage_bucket.kestra_storage.name}/workflows/trends_ingest.yml)

# Execute the workflow
curl -X POST "http://$KESTRA_URL/api/v1/executions" -H "Content-Type: application/json" -d '{"namespace":"Topterms","flowId":"trends_ingest"}'
EOT
}