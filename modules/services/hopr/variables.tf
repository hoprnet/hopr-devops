variable "key" {
  description = "SSH Public Key used for accessing the Daneel’s account"
}
variable "instance_name" {
  description = "The desired name to assign to the deployed instance"
}
variable "project_id" {
  description = "GCP project ID"
}
variable "region" {
  description = "GCP region"
}
variable "zone" {
  description = "GCP zone"
}
variable "instance_count" {
  description = "Number of instances to create."
  type        = number
  default     = 1
}
variable "prefix" {
  description = "Prefix to prepend to resource names."
  type        = string
  default     = ""
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
variable "container_arguments" {
  description = "Container arguments"
}
variable "env_HOST_IPV4" {
  description = "Host HOPR node will listen to"
}
variable "env_BOOTSTRAP_SERVERS" {
  description = "HOPR Bootstrap Servers"
}
variable "env_ETHEREUM_PROVIDER" {
  description = "HOPR Network and Provider"
}
variable "env_DEBUG" {
  description = "HOPR Debug Flags"
}