variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "Default region (เช่น asia-southeast1)"
  type        = string
  default     = "asia-southeast1"
}

variable "dataproc_custom_worker_id" {
  description = <<EOT
ID ของ custom role สำหรับ Dataproc worker (ส่วนท้ายของ role)
เช่น ถ้าใน IAM > Roles แสดงเป็น:
  projects/tlnk-infra-tor/roles/dataproc.customWorker
ให้ใส่ค่าใน var นี้เป็น: dataproc.customWorker
EOT
  type    = string
  default = "dataproc.customWorker"
}

# ------------------------------
# ชื่อ GCS Buckets
# (ต้องมีอยู่แล้ว หรือจะให้ Terraform ตัวอื่นสร้างก็ได้)
# ------------------------------
variable "bucket_a_name" {
  description = "ชื่อ Bucket A (ที่ให้อ่านได้เฉพาะ SA bucket-a-customtest)"
  type        = string
}

variable "bucket_b_name" {
  description = "ชื่อ Bucket B (ที่ให้อ่านได้เฉพาะ SA bucket-b-customtest)"
  type        = string
}

variable "bucket_c_name" {
  description = "ชื่อ Bucket C (ไม่มีการผูก objectViewer ให้ SA ใน config นี้)"
  type        = string
}
