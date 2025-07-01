variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project name to be used for tagging resources"
  type        = string
  default     = "fsx-lustre-demo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type        = string
  default     = "us-east-2a"
}

variable "fsx_deployment_type" {
  description = "The deployment type of the FSx file system (SCRATCH_1, SCRATCH_2, PERSISTENT_1, PERSISTENT_2)"
  type        = string
  default     = "SCRATCH_2"
}

variable "fsx_storage_capacity" {
  description = "The storage capacity of the FSx file system in GiB"
  type        = number
  default     = 1200
}

variable "fsx_per_unit_storage_throughput" {
  description = "Throughput in MB/s/TiB for PERSISTENT_1 deployment types"
  type        = number
  default     = 50
}

variable "fsx_lustre_version" {
  description = "The version of the Lustre file system (2.10, 2.12, or 2.15) - used for file_system_type_version parameter"
  type        = string
  default     = "2.15"
}

variable "existing_vpc_id" {
  description = "ID of the existing VPC to peer with"
  type        = string
  default     = ""
}

# Both existing_vpc_cidr and existing_vpc_route_table_id are no longer needed as we fetch them via data sources
