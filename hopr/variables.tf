variable "name" {
  default     = "hopr-ch-develop-container"
  description = "Name to use in all resources of this module"
}
variable "credentials" {
  default     = "hopr-ch-develop.json"
  description = "Service account credentials JSON file"
}
variable "instance_name" {
  default     = "hopr-ch-develop-001"
  description = "The desired name to assign to the deployed instance"
}
variable "cos_image_name" {
  default     = "cos-stable-81-12871-103-0"
  description = "Container Optimised version number"
}
variable "env_welcome" {
  default     = "Welcome to HOPR"
  description = "Welcome message from our container"
}

# Configurable Variables
variable "project_id" {
  description = "GCP project ID"
}
variable "region" {
  description = "GCP region"
}
variable "zone" {
  description = "GCP zone"
}
variable "client_email" {
  description = "Service account email"
}
variable "container_image" {
  description = "Container image name"
}
variable "image_port" {
  description = "Container listening port"
}
