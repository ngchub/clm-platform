terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" { type = string }
variable "region" { type = string, default = "europe-west1" }
variable "db_password" { type = string, sensitive = true }

resource "google_compute_network" "clm_vpc" {
  name                    = "clm-vpc-prod"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "clm_subnet" {
  name          = "clm-subnet-prod"
  ip_cidr_range = "10.10.0.0/20"
  region        = var.region
  network       = google_compute_network.clm_vpc.id
}

resource "google_vpc_access_connector" "serverless_connector" {
  name          = "clm-vpc-conn"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.clm_vpc.name
  min_instances = 2
  max_instances = 10
  machine_type  = "f1-micro"
}

resource "google_pubsub_topic" "cert_scans_topic" {
  name = "cert.scans"
}

resource "google_pubsub_subscription" "db_writer_sub" {
  name  = "cert-scans-db-writer-sub"
  topic = google_pubsub_topic.cert_scans_topic.name
}
