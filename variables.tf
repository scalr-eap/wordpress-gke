variable "scalr_google_project" {}
variable "scalr_google_credentials" {}

variable mysql_password {}

variable "cluster_name" {
  type    = string
  description = "Cluster to deploy to"
}

variable "region" {
  description = "The GCE Region of the Cluster"
  type        = string
}

variable "service_name" {
  description = "Name to be given to the Wordpress service in GKE"
  type        = string
}
