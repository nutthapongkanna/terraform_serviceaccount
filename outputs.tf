output "service_account_email" {
  description = "อีเมลของ Service Account ที่สร้าง"
  value       = google_service_account.sa.email
}

output "bucket_names" {
  description = "ชื่อ bucket ที่สร้าง"
  value = {
    bucket_a    = google_storage_bucket.bucket_a.name
    bucket_b    = google_storage_bucket.bucket_b.name
    bucket_c    = google_storage_bucket.bucket_c.name
    dp_staging  = google_storage_bucket.dp_staging.name
    dp_temp     = google_storage_bucket.dp_temp.name
  }
}