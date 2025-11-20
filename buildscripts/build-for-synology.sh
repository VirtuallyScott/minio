#!/usr/bin/env bash
#
# Build MinIO Docker image for Synology NAS (linux/amd64)
# This script builds the image and exports it as a gzipped tar file
# that can be loaded on a Synology NAS
#

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PLATFORM="linux/amd64"
VERSION=${VERSION:-$(git describe --tags --always --dirty)}
REPO=${REPO:-"minio"}
IMAGE_NAME=${IMAGE_NAME:-"${REPO}/minio"}
TAG="${IMAGE_NAME}:${VERSION}"
OUTPUT_DIR=${OUTPUT_DIR:-"./dist"}
OUTPUT_FILE="${OUTPUT_DIR}/minio-${VERSION}-amd64.tar.gz"

echo -e "${GREEN}=== Building MinIO Docker Image for Synology ===${NC}"
echo "Platform: ${PLATFORM}"
echo "Image Tag: ${TAG}"
echo "Output File: ${OUTPUT_FILE}"
echo ""

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${YELLOW}Warning: Docker buildx is not available. Using standard docker build.${NC}"
    USE_BUILDX=false
else
    USE_BUILDX=true
fi

# Build the MinIO binary first
echo -e "${GREEN}Step 1: Building MinIO binary...${NC}"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -tags kqueue -trimpath \
    -ldflags "$(go run buildscripts/gen-ldflags.go)" \
    -o "${OUTPUT_DIR}/minio-amd64" .

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build MinIO binary${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MinIO binary built successfully${NC}"
echo ""

# Build Docker image
echo -e "${GREEN}Step 2: Building Docker image for ${PLATFORM}...${NC}"

if [ "${USE_BUILDX}" = true ]; then
    # Use buildx for multi-platform support
    docker buildx build \
        --platform "${PLATFORM}" \
        --tag "${TAG}" \
        --load \
        -f Dockerfile.synology \
        .
else
    # Use standard docker build
    docker build \
        --platform "${PLATFORM}" \
        --tag "${TAG}" \
        -f Dockerfile.synology \
        .
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to build Docker image${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo ""

# Save Docker image to tar.gz
echo -e "${GREEN}Step 3: Exporting Docker image to ${OUTPUT_FILE}...${NC}"

docker save "${TAG}" | gzip > "${OUTPUT_FILE}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to export Docker image${NC}"
    exit 1
fi

# Get file size
FILE_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)

echo -e "${GREEN}✓ Docker image exported successfully${NC}"
echo ""

# Display summary
echo -e "${GREEN}=== Build Complete ===${NC}"
echo "Image: ${TAG}"
echo "Platform: ${PLATFORM}"
echo "File: ${OUTPUT_FILE}"
echo "Size: ${FILE_SIZE}"
echo ""
echo -e "${YELLOW}To load this image on your Synology NAS:${NC}"
echo "1. Copy ${OUTPUT_FILE} to your Synology"
echo "2. SSH into your Synology"
echo "3. Run: gunzip -c minio-${VERSION}-amd64.tar.gz | docker load"
echo "4. Run: docker images | grep minio"
echo ""
echo -e "${YELLOW}To run the container:${NC}"
echo "docker run -d -p 9000:9000 -p 9001:9001 \\"
echo "  -e MINIO_ROOT_USER=admin \\"
echo "  -e MINIO_ROOT_PASSWORD=your-secret-password \\"
echo "  -v /volume1/docker/minio/data:/data \\"
echo "  --name minio ${TAG} server /data --console-address ':9001'"
echo ""
