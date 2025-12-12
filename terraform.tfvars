project_id = "tlnk-infra-tor"
region     = "asia-southeast1"
location   = "asia-southeast1"

# SA เดียวสำหรับ Dataproc / Cloud Run
service_account_id           = "dataproc-customtest"
service_account_display_name = "Dataproc / Cloud Run CustomTest SA"

# จาก IAM:
# projects/tlnk-infra-tor/roles/dataproc.customWorker
dataproc_custom_worker_id = "dataproc.customWorker"

# ตั้งชื่อ bucket สำหรับ lab นี้
bucket_a_name = "ch-bucket-a"
bucket_b_name = "ch-bucket-b"
bucket_c_name = "ch-bucket-c"
