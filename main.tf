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
# 5) init-actions script -> upload ไป bucket B
#    => gs://<bucket_b>/init-actions/setup-common-lib.sh
# ==============================

resource "local_file" "setup_common_lib" {
  filename        = "${path.module}/setup-common-lib.sh"
  file_permission = "0755"

  # ห้ามใช้ ${DEST}/${BUCKET} ใน script (Terraform จะ interpolate)
  # ใช้ $DEST/$BUCKET แทน
  content = <<-EOT
#!/bin/bash
set -euo pipefail

LOG="/var/log/dataproc-setup-common-lib.log"
exec > >(tee -a "$LOG") 2>&1

BUCKET="${var.bucket_b_name}"
PREFIX="test_folder"
DEST="/opt/test_folder"

echo "== Copy common lib from gs://$BUCKET/$PREFIX -> $DEST =="

mkdir -p "$DEST"
gsutil ls "gs://$BUCKET/$PREFIX/" >/dev/null
gsutil -m rsync -r "gs://$BUCKET/$PREFIX" "$DEST"

# ให้ shell เห็น
cat <<'EOF' | tee /etc/profile.d/common-lib.sh >/dev/null
export PYTHONPATH=/opt/test_folder/lib:$PYTHONPATH
EOF
chmod +x /etc/profile.d/common-lib.sh

# ให้ Spark เห็น (สำคัญสำหรับ pyspark บน worker)
if [ -f /etc/spark/conf/spark-env.sh ]; then
  echo "export PYTHONPATH=/opt/test_folder/lib:$PYTHONPATH" >> /etc/spark/conf/spark-env.sh
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

# ==============================
# 7) สร้าง job file ให้เลยใน bucket B
#    => gs://<bucket_b>/jobs/job_test_buckets.py
# ==============================

resource "local_file" "job_test_buckets_py" {
  filename        = "${path.module}/job_test_buckets.py"
  file_permission = "0644"

  content = <<-EOT
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("test-buckets").getOrCreate()

print("### Trying to read from Bucket A (should SUCCESS)")
df_a = spark.read.text("gs://${var.bucket_a_name}/sample_a.txt")
df_a.show(5, truncate=False)

print("### Trying to read from Bucket C (should FAIL)")
try:
    df_c = spark.read.text("gs://${var.bucket_c_name}/sample_c.txt")
    df_c.show(5, truncate=False)
except Exception as e:
    print("EXPECTED FAIL reading Bucket C")
    print(e)

spark.stop()
EOT
}

resource "google_storage_bucket_object" "job_test_buckets_py" {
  bucket       = google_storage_bucket.bucket_b.name
  name         = "jobs/job_test_buckets.py"
  source       = local_file.job_test_buckets_py.filename
  content_type = "text/x-python"

  depends_on = [google_storage_bucket.bucket_b]
}

# ==============================
# 8) (Optional แต่แนะนำ) สร้าง sample files ให้เทสได้ทันที
# ==============================

resource "google_storage_bucket_object" "sample_a" {
  bucket  = google_storage_bucket.bucket_a.name
  name    = "sample_a.txt"
  content = "hello from bucket A\n"
}

resource "google_storage_bucket_object" "sample_c" {
  bucket  = google_storage_bucket.bucket_c.name
  name    = "sample_c.txt"
  content = "hello from bucket C\n"
}
