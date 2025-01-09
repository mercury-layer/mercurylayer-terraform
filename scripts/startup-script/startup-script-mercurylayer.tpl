#!/bin/bash

echo "Starting the startup script execution..."

# Update repositories and upgrade the OS packages
echo "Updating repositories and upgrading packages..."
apt-get update -y
apt-get upgrade -y

# Install dependencies
echo "Installing required packages..."
apt-get install -y ca-certificates curl git jq

# Install Google Cloud Ops Agent
echo "Installing GCP Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Remove conflicting Docker-related packages
echo "Removing conflicting Docker packages..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
  apt-get remove -y $pkg || true
done

# Add Docker's official GPG key
echo "Adding Docker's GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
echo "Installing Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Clone the mercury layer repo
echo "Cloning the mercury layer repo..."
git clone https://github.com/mercury-layer/mercurylayer /mercurylayer

# Run docker-compose-sim.yml
echo "Running docker-compose-sim.yml..."
cd /mercurylayer
docker compose -f docker-compose-sim.yml up -d

# Build the Explorer web server
cd /
cd /mercurylayer/explorer
docker build -t mercurylayer-explorer .
# Run the Explorer web server
docker run -d --name mercurylayer-explorer --rm -p 80:80 mercurylayer-explorer


