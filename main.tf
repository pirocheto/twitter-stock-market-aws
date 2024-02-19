module "data_lake_s3_bucket" {
  source      = "./terraform_modules/s3_bucket"
  bucket_name = "twitter-stock-market-data-storage"
}

module "step_functions" {
  source          = "./terraform_modules/step_functions"
  bucket_name     = module.data_lake_s3_bucket.bucket_name
  finnhub_api_key = file(".FINNHUB_API_KEY")
}

module "glue_job" {
  source          = "./terraform_modules/glue_job"
  glue_job_script = "${path.module}/scripts/glue_job.py"
  bucket_name     = module.data_lake_s3_bucket.bucket_name
}
