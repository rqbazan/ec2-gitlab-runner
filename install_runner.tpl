#!/bin/bash
# Setup GitLab Runner with Docker executor
# For use with `image:` directive in .gitlab-ci.yml

set -x
echo "Setting up GitLab Runner with Docker executor..."

# Update system
yum update -y
yum install -y curl git jq

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

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

# Register GitLab Runner with DOCKER executor
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
  --docker-pull-policy "always"

echo "GitLab Runner with Docker executor configured!"
systemctl status -l gitlab-runner.service