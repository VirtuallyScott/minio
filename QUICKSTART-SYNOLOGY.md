# Quick Reference: Building MinIO for Synology

## One-Command Build

```bash
make docker-synology
```

This builds everything and creates: `dist/minio-<version>-amd64.tar.gz`

## Transfer to Synology

```bash
# Replace with your Synology IP
scp dist/minio-*.tar.gz admin@192.168.1.100:/volume1/docker/
```

## Load on Synology

```bash
ssh admin@192.168.1.100
cd /volume1/docker
gunzip -c minio-*.tar.gz | sudo docker load
```

## Run on Synology

```bash
sudo docker run -d \
  --name minio \
  --restart unless-stopped \
  -p 9000:9000 \
  -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=YourSecurePassword123 \
  -v /volume1/docker/minio/data:/data \
  minio/minio:latest \
  server /data --console-address ':9001'
```

## Access

- Web Console: http://synology-ip:9001
- API Endpoint: http://synology-ip:9000

## Useful Commands

```bash
# Check if running
sudo docker ps | grep minio

# View logs
sudo docker logs minio

# Stop container
sudo docker stop minio

# Start container
sudo docker start minio

# Remove container (keeps data)
sudo docker rm minio

# Update to new version
sudo docker stop minio
sudo docker rm minio
# Then load new image and run again
```

## Notes

- Platform: linux/amd64
- Default data dir on Synology: `/volume1/docker/minio/data`
- Console port: 9001
- API port: 9000
- Min password length: 8 characters
