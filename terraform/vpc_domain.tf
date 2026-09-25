# Serverless VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  name          = "clm-vpc-connector"
  region        = "europe-west1"
  ip_cidr_range = "10.8.0.0/28"
  network       = "default"
  min_instances = 2
  max_instances = 10
  machine_type  = "f1-micro"
}

# Next.js Custom Domain Mapping
resource "google_cloud_run_domain_mapping" "ui_domain" {
  location = "europe-west1"
  name     = "app.sirket.com"

  metadata {
    namespace = var.gcp_project_id
  }

  spec {
    route_name = google_cloud_run_v2_service.ui.name
  }
}
