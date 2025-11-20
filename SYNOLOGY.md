# Building MinIO for Synology NAS

This guide explains how to build a custom MinIO Docker image for your Synology NAS.

## Prerequisites

- Docker installed on your build machine (Mac/Linux)
- Go 1.24.x or later
- SSH access to your Synology NAS
- Docker package installed on Synology

## Quick Start

### 1. Build the Docker Image

From the project root directory, run:

```bash
make docker-synology
```

Or manually:

```bash
./buildscripts/build-for-synology.sh
```

This will:

- Build the MinIO binary for linux/amd64
- Create a Docker image specifically for Synology
- Export the image as `dist/minio-<version>-amd64.tar.gz`

### 2. Transfer to Synology

Copy the generated tar.gz file to your Synology NAS:

```bash
scp dist/minio-*.tar.gz admin@your-synology-ip:/volume1/docker/
```

### 3. Load the Image on Synology

SSH into your Synology and load the image:

```bash
ssh admin@your-synology-ip
cd /volume1/docker/
gunzip -c minio-*.tar.gz | sudo docker load
```

Verify the image is loaded:

```bash
sudo docker images | grep minio
```

### 4. Fix Permissions (CRITICAL!)

MinIO runs as user ID 1000. You **must** fix permissions before starting:

```bash
sudo mkdir -p /volume1/docker/minio/data
sudo chown -R 1000:1000 /volume1/docker/minio/data
sudo chmod -R 755 /volume1/docker/minio/data
```

Or use the provided script (copy from your build machine):

```bash
# On your Mac/build machine
scp buildscripts/fix-synology-permissions.sh admin@your-synology:/tmp/

# On Synology
bash /tmp/fix-synology-permissions.sh /volume1/docker/minio/data
```

### 5. Run MinIO on Synology

```bash
sudo docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=your-secret-password-min-8-chars \
  -v /volume1/docker/minio/data:/data \
  minio/minio:latest \
  server /data --console-address ':9001'
```

### 5. Access MinIO

- **API Endpoint**: http://your-synology-ip:9000
- **Web Console**: http://your-synology-ip:9001
- **Credentials**: Use the MINIO_ROOT_USER and MINIO_ROOT_PASSWORD you set

## Configuration Options

### Environment Variables

- `MINIO_ROOT_USER`: Admin username (default: minioadmin)
- `MINIO_ROOT_PASSWORD`: Admin password (min 8 characters)
- `MINIO_BROWSER`: Enable/disable web console (on/off)
- `MINIO_DOMAIN`: Set custom domain for virtual host style requests
- `MINIO_SERVER_URL`: External URL for MinIO server
- `MINIO_BROWSER_REDIRECT_URL`: External URL for MinIO console

### Advanced Configuration

For distributed mode (multiple drives):

```bash
sudo docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=your-secret-password \
  -v /volume1/docker/minio/data1:/data1 \
  -v /volume2/docker/minio/data2:/data2 \
  -v /volume3/docker/minio/data3:/data3 \
  -v /volume4/docker/minio/data4:/data4 \
  minio/minio:latest \
  server /data{1...4} --console-address ':9001'
```

## Build Customization

### Custom Version

```bash
VERSION=v2024.11.20 make docker-synology
```

### Custom Image Name

```bash
IMAGE_NAME=mylab/minio make docker-synology
```

### Custom Output Directory

```bash
OUTPUT_DIR=/tmp/minio-build make docker-synology
```

## Troubleshooting

### Image Won't Load

If you get "invalid tar header" errors, ensure the file transferred completely:

```bash
# On your Mac, get the checksum
shasum -a 256 dist/minio-*.tar.gz

# On Synology, verify it matches
sha256sum minio-*.tar.gz
```

### Permission Denied

If MinIO can't write to /data, fix permissions:

```bash
sudo chown -R 1000:1000 /volume1/docker/minio/data
sudo chmod -R 755 /volume1/docker/minio/data
```

**Common errors:**
- `file access denied`
- `unable to create (/data/.minio.sys/tmp)`
- `unable to rename (/data/.minio.sys/tmp -> ...)`

These all indicate permission issues. MinIO runs as UID 1000 and needs full access to the data directory.

### Container Won't Start

Check logs:

```bash
sudo docker logs minio
```

Common issues:
- **Showing help instead of starting**: The default CMD now includes `server /data --console-address ':9001'`, but if you see help output, explicitly add the command:
  ```bash
  docker run ... minio/minio:latest server /data --console-address ':9001'
  ```
- Password too short (must be 8+ characters)
- Port already in use
- Insufficient disk space
- Permission issues with /data directory

## Updating MinIO

To update to a new version:

1. Stop and remove the old container:
   ```bash
   sudo docker stop minio
   sudo docker rm minio
   ```

2. Build new image with updated code:
   ```bash
   git pull upstream main
   make docker-synology
   ```

3. Transfer and load new image as described above

4. Start new container (data persists in volumes)

## Docker Compose (Alternative)

Create `/volume1/docker/minio/docker-compose.yml`:

```yaml
version: '3.8'

services:
  minio:
    image: minio/minio:latest
    container_name: minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: your-secret-password
    volumes:
      - /volume1/docker/minio/data:/data
    command: server /data --console-address ':9001'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
```

Run with:

```bash
cd /volume1/docker/minio
sudo docker-compose up -d
```

## Platform Details

- **Target Platform**: linux/amd64
- **Base Image**: Alpine Linux (minimal size)
- **User**: Runs as non-root user (UID 1000)
- **Volumes**: /data
- **Ports**: 9000 (API), 9001 (Console)

## Additional Resources

- [MinIO Documentation](https://min.io/docs/minio/linux/index.html)
- [Synology Docker Guide](https://www.synology.com/en-us/dsm/packages/Docker)
- [Git Flow Documentation](./GITFLOW.md)
