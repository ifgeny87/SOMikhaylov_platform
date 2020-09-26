variable "project" {
  description = "Project ID"
}

variable "region" {
  description = "Region"
}

variable "zone" {
  description = "Zone"
}

variable "user" {
  description = "user used for ssh access"
}

variable "public_key_path" {
  description = "Path to the public key used for ssh access"
}

variable "disk_image" {
  description = "Disk image"
}

variable "creds" {
  description = "gcloud credential path"
}