#!/bin/bash
# Setup GitLab Runner with Docker executor and enhanced disk management
# For use with `image:` directive in .gitlab-ci.yml

set -x
echo "Setting up GitLab Runner with Docker executor and disk optimization..."

# Update system
yum update -y
yum install -y curl git jq

# Setup additional EBS volume for Docker data
echo "Setting up Docker data volume..."
# Wait for the volume to be attached

sleep 10

# Check if the volume is attached
if [ -b /dev/xvdf ]; then
    # Format the volume if it's not already formatted
    if ! blkid /dev/xvdf; then
        mkfs.ext4 /dev/xvdf
    fi
    
    # Create mount point and mount the volume
    mkdir -p /var/lib/docker
    mount /dev/xvdf /var/lib/docker
    
    # Add to fstab for persistent mounting
    echo "/dev/xvdf /var/lib/docker ext4 defaults,nofail 0 2" >> /etc/fstab
    
    # Set proper permissions
    chown root:root /var/lib/docker
    chmod 711 /var/lib/docker
fi

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Configure Docker daemon with cleanup settings
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Restart Docker to apply configuration
systemctl restart docker

# Install GitLab Runner
curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
chmod +x /usr/local/bin/gitlab-runner

# Create GitLab Runner user and add to docker group
useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
usermod -aG docker gitlab-runner
usermod -aG docker ec2-user

# Start GitLab Runner service
/usr/local/bin/gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
/usr/local/bin/gitlab-runner start

# Register GitLab Runner with DOCKER executor and cleanup settings
/usr/local/bin/gitlab-runner register --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "${gitlab_runner_registration_token}" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "AWS Docker Executor Runner" \
  --tag-list "aws,linux,docker" \
  --run-untagged="true" \
  --locked="false" \
  --docker-privileged="true" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
  --docker-pull-policy "if-not-present"

# Enable and start services
systemctl enable crond
systemctl start crond

echo "GitLab Runner with Docker executor and disk optimization configured!"
echo "Docker data volume mounted at /var/lib/docker"
echo "Automatic cleanup configured via cron jobs"

# Display disk usage
df -h
docker system df

systemctl status -l gitlab-runner.service