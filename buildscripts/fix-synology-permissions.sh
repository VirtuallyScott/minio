#!/usr/bin/env bash
#
# Fix MinIO permissions on Synology NAS
# Run this script on your Synology to set proper permissions for MinIO data directory
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default data directory
DATA_DIR="${1:-/volume1/docker/minio/data}"

echo -e "${GREEN}=== MinIO Synology Permission Fix ===${NC}"
echo "Data directory: ${DATA_DIR}"
echo ""

# Check if directory exists
if [ ! -d "${DATA_DIR}" ]; then
    echo -e "${YELLOW}Directory does not exist. Creating it...${NC}"
    sudo mkdir -p "${DATA_DIR}"
fi

# Fix ownership to UID/GID 1000 (matches MinIO container user)
echo -e "${GREEN}Setting ownership to 1000:1000...${NC}"
sudo chown -R 1000:1000 "${DATA_DIR}"

# Set proper permissions
echo -e "${GREEN}Setting permissions to 755...${NC}"
sudo chmod -R 755 "${DATA_DIR}"

# Show current permissions
echo ""
echo -e "${GREEN}Current permissions:${NC}"
ls -la "${DATA_DIR}"

echo ""
echo -e "${GREEN}✓ Permissions fixed successfully!${NC}"
echo ""
echo -e "${YELLOW}You can now start the MinIO container:${NC}"
echo "sudo docker run -d --name minio --restart unless-stopped \\"
echo "  -p 9000:9000 -p 9001:9001 \\"
echo "  -e MINIO_ROOT_USER=admin \\"
echo "  -e MINIO_ROOT_PASSWORD=YourSecurePassword123 \\"
echo "  -v ${DATA_DIR}:/data \\"
echo "  minio/minio:latest"
