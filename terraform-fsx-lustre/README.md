# Terraform AWS FSx Lustre File System Project

This Terraform project sets up a standalone AWS FSx Lustre file system with all the necessary networking components:

- VPC with Internet Gateway
- Subnet for the FSx Lustre file system
- Security Group allowing access from within the VPC
- Standalone FSx Lustre file system (without S3 data repository integration)
- VPC Peering to connect with another existing VPC (optional)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or newer)
- AWS CLI configured with appropriate credentials
- An existing VPC ID and CIDR (for peering, optional)

## Usage

1. Clone this repository or copy the files to your local environment.

2. Update the variables in `terraform.tfvars` or provide them via command line:

   Create a `terraform.tfvars` file with contents like:

   ```hcl
   region                     = "us-west-2"
   project_name               = "fsx-lustre-demo"
   vpc_cidr                   = "10.0.0.0/16"
   subnet_cidr                = "10.0.1.0/24"
   availability_zone          = "us-west-2a"
   fsx_deployment_type        = "SCRATCH_2"
   fsx_storage_capacity       = 1200
   fsx_per_unit_storage_throughput = 50
   fsx_lustre_version         = "2.15" # Latest version available (sets file_system_type_version)
   existing_vpc_id            = "vpc-12345678" # Optional, for VPC peering
   ```

3. Initialize Terraform:

   ```bash
   terraform init
   ```

4. Plan the deployment:

   ```bash
   terraform plan
   ```

5. Apply the configuration:

   ```bash
   terraform apply
   ```

6. After successful deployment, Terraform will output details including the FSx Lustre DNS name and mounting instructions.

## FSx Lustre Deployment Types

- `SCRATCH_1`: Temporary storage, optimized for cost (100 MB/s/TiB)
- `SCRATCH_2`: Temporary storage with higher performance (200 MB/s/TiB)
- `PERSISTENT_1`: Long-term storage with throughput specified via `per_unit_storage_throughput`
- `PERSISTENT_2`: Latest generation persistent file system with throughput specified via `per_unit_storage_throughput`

## Lustre Version Options (file_system_type_version)

- `2.10`: Original version
- `2.12`: Improved version with enhanced metadata performance
- `2.15`: Latest version with the most features and best performance

This project is configured to use Lustre version 2.15 by default (via the `file_system_type_version` parameter). This project configures a standalone FSx Lustre filesystem without any S3 data repository integration. If you need to integrate with an S3 bucket for data import/export, you'll need to add the appropriate configuration parameters.

## Mounting the FSx Lustre File System

After deployment, follow the instructions in the `mount_instructions` output to mount the file system on your EC2 instances.

## VPC Peering

If you provide an existing VPC ID:

1. The project will automatically retrieve the CIDR block of the existing VPC
2. It will create a VPC peering connection between the new VPC and the existing VPC
3. It will configure routes in the new VPC to route traffic to the existing VPC
4. It will automatically find all route tables in the existing VPC and add routes back to the FSx VPC

## Clean Up

To destroy the resources created by this Terraform project:

```bash
terraform destroy
```

## Notes

- The FSx Lustre file system requires at least 1.2 TiB of storage capacity
- For production workloads, consider using the `PERSISTENT_1` or `PERSISTENT_2` deployment types
- Ensure that the subnet's availability zone supports FSx Lustre
- Security groups are configured to allow all traffic from within the VPC and from the peered VPC
- This configuration creates a standalone FSx Lustre filesystem without S3 integration. To add S3 data repository integration, you would need to add `import_path` and optionally `auto_import_policy` and `export_path` parameters