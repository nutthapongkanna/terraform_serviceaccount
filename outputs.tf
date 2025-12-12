output "service_account_emails" {
  description = "อีเมลของ Service Accounts ทั้ง 3 ตัว"
  value       = local.sa_emails
}

output "bucket_names" {
  description = "ชื่อ bucket ที่สร้าง"
  value = {
    bucket_a = google_storage_bucket.bucket_a.name
    bucket_b = google_storage_bucket.bucket_b.name
    bucket_c = google_storage_bucket.bucket_c.name
  }
}
