project_id = "tlnk-infra-tor"
region     = "asia-southeast1"
location   = "asia-southeast1"

# SA ใหม่ (ไม่ชนตัวเก่า)
service_account_id           = "dataproc-customtest-lab2"
service_account_display_name = "Dataproc / Cloud Run SA (lab2)"

# จาก IAM:
# projects/tlnk-infra-tor/roles/dataproc.customWorker
dataproc_custom_worker_id = "dataproc.customWorker"

# Buckets ใหม่ (ไม่ชนของเดิม ch-bucket-a/b/c)
bucket_a_name = "ch-bucket-a-lab2"
bucket_b_name = "ch-bucket-b-lab2"
bucket_c_name = "ch-bucket-c-lab2"
