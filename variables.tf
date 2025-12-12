variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region (เช่น asia-southeast1)"
  type        = string
  default     = "asia-southeast1"
}

variable "location" {
  description = "GCS bucket location (เช่น asia-southeast1)"
  type        = string
  default     = "asia-southeast1"
}

variable "service_account_id" {
  description = <<EOT
Service account ID (ส่วนหน้า ก่อน @)
- ตัวเล็ก / ตัวเลข / dash เท่านั้น
- ไม่เกิน 30 ตัวอักษร
ตัวอย่าง: "dataproc-customtest"
EOT
  type = string
}

variable "service_account_display_name" {
  description = "ชื่อแสดงของ Service Account ใน console"
  type        = string
  default     = "Dataproc / Cloud Run SA"
}

variable "dataproc_custom_worker_id" {
  description = <<EOT
ID ของ custom role สำหรับ Dataproc worker (ส่วนท้ายของ role)
เช่น ถ้า IAM Role แสดงเป็น:
  projects/tlnk-infra-tor/roles/dataproc.customWorker
ให้ใส่ค่าใน var นี้เป็น: dataproc.customWorker
EOT
  type    = string
  default = "dataproc.customWorker"
}

# ------------------------------
# ชื่อ GCS Buckets
# ------------------------------
variable "bucket_a_name" {
  description = "ชื่อ Bucket A (ให้อ่านได้)"
  type        = string
}

variable "bucket_b_name" {
  description = "ชื่อ Bucket B (ให้อ่านได้ เช่น เก็บ libs)"
  type        = string
}

variable "bucket_c_name" {
  description = "ชื่อ Bucket C (ไม่ให้ objectViewer)"
  type        = string
}
