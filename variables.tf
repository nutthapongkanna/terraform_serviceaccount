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

# ชื่อ bucket (จะถูกใช้ตอนสร้าง + ผูก IAM)
variable "bucket_a_name" {
  description = "ชื่อ Bucket A"
  type        = string
}

variable "bucket_b_name" {
  description = "ชื่อ Bucket B"
  type        = string
}

variable "bucket_c_name" {
  description = "ชื่อ Bucket C"
  type        = string
}
