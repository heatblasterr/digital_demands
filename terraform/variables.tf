variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default = "trendsinsight-76709"
}

variable "credentials" {
  description =  " "
  type = string
  default = "home/admin1/spark-warehouse/keys/keys-trends.json"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "service_id" {
    description = "GCP SERVICE ACCOUNR ID"
    type = string 
    default = "terraform-serviceacc"
}