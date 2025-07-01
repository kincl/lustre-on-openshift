# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.fsx_vpc.id
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.fsx_subnet.id
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.fsx_sg.id
}

# VPC Peering Outputs
output "peering_status" {
  description = "Status of VPC peering configuration"
  value       = var.existing_vpc_id != "" ? "VPC peering configured with ${var.existing_vpc_id}" : "No VPC peering configured"
}

output "vpc_peering_connection_id" {
  description = "The ID of the VPC peering connection"
  value       = var.existing_vpc_id != "" ? aws_vpc_peering_connection.peer[0].id : ""
}

output "peer_vpc_cidr" {
  description = "The CIDR block of the peered VPC"
  value       = var.existing_vpc_id != "" ? data.aws_vpc.peer_vpc[0].cidr_block : ""
}

output "peer_vpc_route_tables" {
  description = "The route table IDs of the peered VPC"
  value       = var.existing_vpc_id != "" ? data.aws_route_tables.peer_vpc_route_tables[0].ids : []
}

# Instructions for mounting the FSx Lustre filesystem
output "mount_instructions" {
  description = "Instructions for mounting the FSx Lustre filesystem"
  value       = <<EOT
To mount the FSx Lustre filesystem:

1. Install the Lustre client:
   Amazon Linux/RHEL/CentOS:
   sudo yum install -y lustre-client

   Ubuntu/Debian:
   sudo apt-get update
   sudo apt-get install -y lustre-client-modules-$(uname -r)

2. Create a mount point:
   sudo mkdir -p /mnt/fsx

3. Mount the filesystem:
   sudo mount -t lustre ${aws_fsx_lustre_file_system.lustre.dns_name}@tcp:/${aws_fsx_lustre_file_system.lustre.mount_name} /mnt/fsx

4. Verify the mount:
   df -h | grep fsx

5. To mount automatically on boot, add this line to /etc/fstab:
   ${aws_fsx_lustre_file_system.lustre.dns_name}@tcp:/${aws_fsx_lustre_file_system.lustre.mount_name} /mnt/fsx lustre defaults,_netdev 0 0
EOT
}
