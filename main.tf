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
# 1) กำหนด service accounts 3 ตัว
# ==============================
locals {
  service_accounts = {
    "bucket-a-customtest" = "Bucket A Custom Test SA"
    "bucket-b-customtest" = "Bucket B Custom Test SA"
    "bucket-c-customtest" = "Bucket C Custom Test SA"
  }
}

# ==============================
# 2) สร้าง Service Account ทั้ง 3 ตัว
# ==============================
resource "google_service_account" "sa" {
  for_each = local.service_accounts

  project      = var.project_id
  account_id   = each.key          # bucket-a-customtest / bucket-b-customtest / bucket-c-customtest
  display_name = each.value
}

# map: key = account_id, value = email
locals {
  sa_emails = { for k, sa in google_service_account.sa : k => sa.email }
}

# ==============================
# 3) ผูก PROJECT ROLES ให้กับ SA ทุกตัว
# ==============================

# Artifact Registry Reader
resource "google_project_iam_member" "artifactregistry_reader" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${each.value}"
}

# Cloud Build Editor
resource "google_project_iam_member" "cloudbuild_editor" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${each.value}"
}

# Cloud Run Admin
resource "google_project_iam_member" "cloudrun_admin" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${each.value}"
}

# Dataproc Editor
resource "google_project_iam_member" "dataproc_editor" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${each.value}"
}

# Logs Writer
resource "google_project_iam_member" "logs_writer" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${each.value}"
}

# Service Account User
resource "google_project_iam_member" "sa_user" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${each.value}"
}

# Service Usage Admin
resource "google_project_iam_member" "serviceusage_admin" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${each.value}"
}

# Dataproc Custom Worker (Custom role)
resource "google_project_iam_member" "dataproc_custom_worker" {
  for_each = local.sa_emails

  project = var.project_id
  role    = "projects/${var.project_id}/roles/${var.dataproc_custom_worker_id}"
  member  = "serviceAccount:${each.value}"
}

# ==============================
# 4) GCS BUCKET IAM (READ PERMISSIONS)
#
#    - bucket-a-customtest → อ่านได้เฉพาะ Bucket A
#    - bucket-b-customtest → อ่านได้เฉพาะ Bucket B
#    - bucket-c-customtest → ไม่ได้สิทธิอ่าน (ไม่มี resource ให้)
# ==============================

# Bucket A: ให้ roles/storage.objectViewer กับ SA bucket-a-customtest เท่านั้น
resource "google_storage_bucket_iam_member" "bucket_a_viewer" {
  for_each = {
    for k, email in local.sa_emails :
    k => email
    if k == "bucket-a-customtest"
  }

  bucket = var.bucket_a_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${each.value}"
}

# Bucket B: ให้ roles/storage.objectViewer กับ SA bucket-b-customtest เท่านั้น
resource "google_storage_bucket_iam_member" "bucket_b_viewer" {
  for_each = {
    for k, email in local.sa_emails :
    k => email
    if k == "bucket-b-customtest"
  }

  bucket = var.bucket_b_name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${each.value}"
}

# **ไม่มี resource สำหรับ Bucket C**
# => ไม่มี SA ตัวไหนได้ roles/storage.objectViewer จาก Terraform ตัวนี้
#    โดยเฉพาะ bucket-c-customtest จะ "ไม่ควรอ่านได้" ตามที่ต้องการ
