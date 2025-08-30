terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network (Free)
resource "google_compute_network" "vpc" {
  name                    = "secure-app-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "secure-app-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# VPC Connector (Free tier: 1 connector)
resource "google_vpc_access_connector" "connector" {
  name          = "secure-connector"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.vpc.name
  min_instances = 2
  max_instances = 3
}

# Private IP for Cloud SQL
resource "google_compute_global_address" "private_ip" {
  name          = "private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
}

# Cloud SQL (Smallest instance)
resource "google_sql_database_instance" "postgres" {
  name                = "secure-db"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    disk_size = 10
    disk_type = "PD_HDD"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
      require_ssl     = false
    }

    backup_configuration {
      enabled = false  # Disable to save costs
    }
  }

  depends_on = [google_service_networking_connection.private_vpc]
}

resource "google_sql_database" "database" {
  name     = "appdb"
  instance = google_sql_database_instance.postgres.name
}

resource "random_password" "db_password" {
  length  = 12
  special = false  # Simplified for demo
}

resource "google_sql_user" "user" {
  name     = "appuser"
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_password.result
}

# Secret Manager (Free: 10K operations)
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Service Account
resource "google_service_account" "cloud_run_sa" {
  account_id   = "secure-app-sa"
  display_name = "Cloud Run SA"
}

resource "google_project_iam_member" "cloud_run_roles" {
  for_each = toset([
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor"
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Artifact Registry (Free: 0.5GB)
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = "secure-repo"
  format        = "DOCKER"
}

# Cloud Run Service (Free: 2M requests)
resource "google_cloud_run_v2_service" "app" {
  name     = "secure-app"
  location = var.region

  template {
    service_account = google_service_account.cloud_run_sa.email
    
    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/secure-repo/secure-nodejs-app:latest"
      
      ports {
        container_port = 8080
      }

      env {
        name  = "DB_HOST"
        value = google_sql_database_instance.postgres.private_ip_address
      }
      
      env {
        name  = "DB_NAME"
        value = google_sql_database.database.name
      }
      
      env {
        name  = "DB_USER"
        value = google_sql_user.user.name
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "256Mi"  # Reduced for free tier
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 3  # Limited for demo
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# Public access
resource "google_cloud_run_service_iam_member" "public" {
  service  = google_cloud_run_v2_service.app.name
  location = google_cloud_run_v2_service.app.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}