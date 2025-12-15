terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
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
  force_destroy = true
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
# 1.1) สร้าง Dataproc staging/temp buckets
# ==============================

resource "google_storage_bucket" "dp_staging" {
  name          = var.dp_staging_bucket_name
  location      = var.location
  force_destroy = true
}

resource "google_storage_bucket" "dp_temp" {
  name          = var.dp_temp_bucket_name
  location      = var.location
  force_destroy = true
}

# ==============================
# 2) สร้าง Service Account
# ==============================

resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

locals {
  sa_email  = google_service_account.sa.email
  sa_member = "serviceAccount:${local.sa_email}"
}

# ==============================
# 3) PROJECT ROLES ให้ SA
# ==============================

resource "google_project_iam_member" "artifactregistry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = local.sa_member
}

resource "google_project_iam_member" "cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = local.sa_member
}

resource "google_project_iam_member" "cloudrun_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = local.sa_member
}

resource "google_project_iam_member" "dataproc_editor" {
  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = local.sa_member
}

resource "google_project_iam_member" "logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = local.sa_member
}

resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = local.sa_member
}

resource "google_project_iam_member" "serviceusage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = local.sa_member
}

resource "google_project_iam_member" "dataproc_custom_worker" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${var.dataproc_custom_worker_id}"
  member  = local.sa_member
}

# ==============================
# 4) BUCKET IAM
#   - A,B: objectViewer
#   - C: no access
# ==============================

resource "google_storage_bucket_iam_member" "bucket_a_viewer" {
  bucket = google_storage_bucket.bucket_a.name
  role   = "roles/storage.objectViewer"
  member = local.sa_member
}

resource "google_storage_bucket_iam_member" "bucket_b_viewer" {
  bucket = google_storage_bucket.bucket_b.name
  role   = "roles/storage.objectViewer"
  member = local.sa_member
}

# ==============================
# 4.1) Dataproc staging/temp: Storage Admin
# ==============================

resource "google_storage_bucket_iam_member" "dp_staging_storage_admin" {
  bucket = google_storage_bucket.dp_staging.name
  role   = "roles/storage.admin"
  member = local.sa_member
}

resource "google_storage_bucket_iam_member" "dp_temp_storage_admin" {
  bucket = google_storage_bucket.dp_temp.name
  role   = "roles/storage.admin"
  member = local.sa_member
}

# ==============================
# 5) สร้าง init script (local) แล้ว upload ไป bucket B
#    => gs://<bucket_b>/init-actions/setup-common-lib.sh
# ==============================

resource "local_file" "setup_common_lib" {
  filename        = "${path.module}/setup-common-lib.sh"
  file_permission = "0755"

  content = <<-EOT
  #!/bin/bash
  set -euo pipefail

  LOG="/var/log/dataproc-setup-common-lib.log"
  exec > >(tee -a "$LOG") 2>&1

  BUCKET="${var.bucket_b_name}"
  PREFIX="test_folder"
  DEST="/opt/test_folder"

  echo "== Copy common lib from gs://${BUCKET}/${PREFIX} -> ${DEST} =="

  mkdir -p "${DEST}"
  gsutil ls "gs://${BUCKET}/${PREFIX}/" >/dev/null
  gsutil -m rsync -r "gs://${BUCKET}/${PREFIX}" "${DEST}"

  # ให้ shell เห็น
  cat <<EOF | tee /etc/profile.d/common-lib.sh >/dev/null
  export PYTHONPATH=${DEST}/lib:\\$PYTHONPATH
  EOF
  chmod +x /etc/profile.d/common-lib.sh

  # ให้ Spark เห็น (สำคัญสำหรับ pyspark บน worker)
  if [ -f /etc/spark/conf/spark-env.sh ]; then
    echo "export PYTHONPATH=${DEST}/lib:\\$PYTHONPATH" >> /etc/spark/conf/spark-env.sh
  fi

  echo "== SUCCESS =="
  EOT
}

resource "google_storage_bucket_object" "setup_common_lib" {
  name         = "init-actions/setup-common-lib.sh"
  bucket       = google_storage_bucket.bucket_b.name
  source       = local_file.setup_common_lib.filename
  content_type = "text/x-shellscript"

  depends_on = [google_storage_bucket.bucket_b]
}

# ==============================
# 6) สร้างไฟล์ให้ "โฟลเดอร์" โผล่ใน bucket B
#    => gs://<bucket_b>/test_folder/lib/app.py
# ==============================

resource "local_file" "common_app_py" {
  filename        = "${path.module}/app.py"
  file_permission = "0644"

  content = <<-EOT
  def hello():
      return "hello from common lib"
  EOT
}

resource "google_storage_bucket_object" "common_app_py" {
  bucket       = google_storage_bucket.bucket_b.name
  name         = "test_folder/lib/app.py"
  source       = local_file.common_app_py.filename
  content_type = "text/x-python"

  depends_on = [google_storage_bucket.bucket_b]
}
