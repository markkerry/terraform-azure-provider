variable "prefix" {
  description = "Prefix for the resource names"
}

variable "location" {
  default     = "UK South"
  description = "Region location for the resources"
}

variable "instance_count" {
  description = "Number of VMs to deploy"
}