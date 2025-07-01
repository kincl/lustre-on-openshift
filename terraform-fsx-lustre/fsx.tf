# FSx Lustre File System
resource "aws_fsx_lustre_file_system" "lustre" {
  storage_capacity   = var.fsx_storage_capacity
  subnet_ids         = [aws_subnet.fsx_subnet.id]
  deployment_type    = var.fsx_deployment_type
  security_group_ids = [aws_security_group.fsx_sg.id]

  # Only applicable for PERSISTENT deployment types
  per_unit_storage_throughput = var.fsx_deployment_type == "PERSISTENT_1" || var.fsx_deployment_type == "PERSISTENT_2" ? var.fsx_per_unit_storage_throughput : null

  # Additional configuration options
  storage_type             = "SSD"
  file_system_type_version = var.fsx_lustre_version

  tags = {
    Name = "${var.project_name}-lustre-fs"
  }

  # Additional optional settings
  # weekly_maintenance_start_time   = "2:05:00"
  # automatic_backup_retention_days = 7  # Only valid with PERSISTENT deployment types
  # copy_tags_to_backups            = true
}

# Outputs for FSx Lustre File System
output "fsx_lustre_id" {
  description = "The ID of the FSx Lustre file system"
  value       = aws_fsx_lustre_file_system.lustre.id
}

output "fsx_lustre_dns_name" {
  description = "The DNS name for the FSx Lustre file system"
  value       = aws_fsx_lustre_file_system.lustre.dns_name
}

output "fsx_lustre_mount_name" {
  description = "The mount name of the FSx Lustre file system"
  value       = aws_fsx_lustre_file_system.lustre.mount_name
}
