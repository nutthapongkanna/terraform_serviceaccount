terraform {
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

# ==============================
# 1) สร้าง GCS BUCKET A/B/C
# ==============================

resource "google_storage_bucket" "bucket_a" {
  name          = var.bucket_a_name
  location      = var.location
  force_destroy = true  # ลบ bucket พร้อม object ได้ (สำหรับ lab)
}

resource "google_storage_bucket" "bucket_b" {
  name          = var.bucket_b_name
  location      = var.location
  force_destroy = true
}

resource "google_storage_bucket" "bucket_c" {
  name          = var.bucket_c_name
  location      = var.location
  force_destroy = true
}

# ==============================
# 2) สร้าง Service Account เดียว
# ==============================

resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

locals {
  sa_email = google_service_account.sa.email
}

# ==============================
# 3) แนบ PROJECT ROLES ให้ SA เดียว
# ==============================

# Artifact Registry Reader
resource "google_project_iam_member" "artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${local.sa_email}"
}

# Cloud Build Editor
resource "google_project_iam_member" "cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${local.sa_email}"
}

# Cloud Run Admin
resource "google_project_iam_member" "cloudrun_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${local.sa_email}"
}

# Dataproc Editor
resource "google_project_iam_member" "dataproc_editor" {
  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${local.sa_email}"
}

# Logs Writer
resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${local.sa_email}"
}

# Service Account User
resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${local.sa_email}"
}

# Service Usage Admin
resource "google_project_iam_member" "serviceusage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${local.sa_email}"
}

# Dataproc Custom Worker (Custom role)
resource "google_project_iam_member" "dataproc_custom_worker" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${var.dataproc_custom_worker_id}"
  member  = "serviceAccount:${local.sa_email}"
}

# ==============================
# 4) GCS BUCKET IAM (READ PERMISSIONS)
#
#   - SA เดียวนี้:
#       * อ่านได้: Bucket A + Bucket B
#       * ห้ามอ่าน: Bucket C (ไม่มี objectViewer ให้)
# ==============================

resource "google_storage_bucket_iam_member" "bucket_a_viewer" {
  bucket = google_storage_bucket.bucket_a.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.sa_email}"
}

resource "google_storage_bucket_iam_member" "bucket_b_viewer" {
  bucket = google_storage_bucket.bucket_b.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${local.sa_email}"
}

# ❗ ไม่มี iam_member สำหรับ bucket C
# => SA นี้จะไม่มี roles/storage.objectViewer บน bucket C จาก config นี้
