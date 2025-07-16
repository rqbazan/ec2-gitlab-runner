# AWS EC2 GitLab Runner with Terraform

This repository contains Terraform configuration to deploy a GitLab Runner on AWS EC2 with Docker executor and optimized disk management.

## Overview

This setup creates:

- An EC2 instance running Amazon Linux 2
- A security group allowing SSH access
- An additional EBS volume dedicated for Docker data
- Automated GitLab Runner installation and configuration
- Docker executor with cleanup and optimization settings

## Features

- **Dedicated Docker Volume**: Separate EBS volume for Docker data to prevent disk space issues
- **Encrypted Storage**: Both root and Docker volumes are encrypted
- **Optimized Configuration**: Docker daemon configured with log rotation and cleanup
- **Docker Executor**: Supports running GitLab CI/CD jobs in Docker containers
- **Flexible Instance Types**: Configurable instance size based on workload requirements

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (version 0.14+)
- AWS CLI configured with appropriate credentials
- An existing EC2 Key Pair in your target AWS region
- GitLab Runner registration token from your GitLab project/group

## Quick Start

1. **Clone the repository**

   ```bash
   git clone git@github.com:rqbazan/ec2-gitlab-runner.git
   cd ec2-gitlab-runner
   ```

2. **Configure variables**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Edit [`terraform.tfvars`](terraform.tfvars) with your values:

   ```hcl
   aws_region                       = "us-east-1"
   instance_type                    = "t3.large"
   key_name                         = "your-key-pair-name"
   gitlab_runner_registration_token = "your-registration-token"
   root_volume_size                 = 30
   docker_volume_size               = 50
   ```

3. **Initialize Terraform**

   ```bash
   terraform init
   ```

4. **Plan the deployment**

   ```bash
   terraform plan
   ```

5. **Apply the configuration**

   ```bash
   terraform apply
   ```

6. **Get the instance details**
   ```bash
   terraform output
   ```

## Configuration Variables

| Variable                                           | Description                      | Type   | Default             |
| -------------------------------------------------- | -------------------------------- | ------ | ------------------- |
| [`aws_region`](variables.tf)                       | AWS region to deploy resources   | string | `us-east-1`         |
| [`instance_type`](variables.tf)                    | EC2 instance type                | string | `t2.micro`          |
| [`key_name`](variables.tf)                         | EC2 Key Pair name for SSH access | string | `gitlab-runner-key` |
| [`gitlab_runner_registration_token`](variables.tf) | GitLab Runner registration token | string | -                   |
| [`root_volume_size`](variables.tf)                 | Root EBS volume size in GB       | number | `30`                |
| [`docker_volume_size`](variables.tf)               | Docker EBS volume size in GB     | number | `50`                |

## Instance Configuration

The EC2 instance is configured with:

- **AMI**: Amazon Linux 2 (ami-03972092c42e8c0ca)
- **Security Group**: Allows SSH (port 22) from anywhere
- **Root Volume**: Encrypted GP3 volume (configurable size)
- **Docker Volume**: Separate encrypted GP3 volume mounted at `/var/lib/docker`

## GitLab Runner Setup

The [`install_runner.tpl`](install_runner.tpl) script automatically:

- Updates the system and installs required packages
- Formats and mounts the dedicated Docker volume
- Installs and configures Docker with optimization settings
- Downloads and installs GitLab Runner
- Registers the runner with Docker executor
- Configures automatic cleanup and monitoring

## Runner Configuration

The GitLab Runner is configured with:

- **Executor**: Docker
- **Default Image**: alpine:latest
- **Privileged Mode**: Enabled
- **Docker Socket**: Mounted for Docker-in-Docker support
- **Tags**: aws, linux, docker
- **Pull Policy**: if-not-present (for efficiency)

## Outputs

After deployment, you'll get:

- [`instance_id`](output.tf): The EC2 instance ID
- [`instance_public_ip`](output.tf): The public IP address for SSH access

## SSH Access

Connect to your instance:

```bash
ssh -i /path/to/your-key.pem ec2-user@<instance_public_ip>
```

## Monitoring

Check GitLab Runner status:

```bash
sudo systemctl status gitlab-runner
sudo /usr/local/bin/gitlab-runner status
```

Monitor disk usage:

```bash
df -h
docker system df
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Security Considerations

- The security group allows SSH access from anywhere (0.0.0.0/0). Consider restricting this to your IP range.
- Both EBS volumes are encrypted at rest.
- The GitLab Runner registration token is marked as sensitive in Terraform.

## Troubleshooting

### Runner not appearing in GitLab

- Verify the registration token is correct
- Check runner logs: `sudo journalctl -u gitlab-runner -f`

### Disk space issues

- The dedicated Docker volume should prevent most disk space issues
- Monitor with: `docker system prune` for cleanup

### Connection issues

- Ensure your key pair exists in the specified AWS region
- Verify security group settings allow SSH access

## License

This project is open source and available under the MIT License.
