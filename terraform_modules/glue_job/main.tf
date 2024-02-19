locals {
  package_bucket = "s3://aws-glue-studio-transforms-371299348807-prod-eu-west-3"
}


resource "aws_s3_object" "job_script" {
  bucket = var.bucket_name
  key    = "scripts/glue_job.py"
  source = var.glue_job_script

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5(var.glue_job_script)
}


resource "aws_glue_job" "glue_job" {
  name              = "glue_job_test_terr"
  role_arn          = aws_iam_role.glue_role.arn
  glue_version      = "4.0"
  worker_type       = "G.1X"
  number_of_workers = 10


  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/${aws_s3_object.job_script.key}"
    python_version  = 3
  }

  default_arguments = {
    "--enable-continuous-cloudwatch-log" = true
    "--enable-continuous-log-filter"     = true
    "--enable-metrics"                   = true
    "--enable-job-insights"              = true
    "--job-language"                     = "python"
    "--enable-observability-metrics"     = true
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--enable-auto-scaling"              = true
    "--extra-py-files"                   = "${local.package_bucket}/gs_common.py,${local.package_bucket}/gs_split.py,${local.package_bucket}/gs_array_to_cols.py,${local.package_bucket}/gs_explode.py,${local.package_bucket}/gs_flatten.py"
  }
}

