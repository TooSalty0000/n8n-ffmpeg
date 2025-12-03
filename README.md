# n8n-ffmpeg

Audio merge server for n8n workflows. Accepts multiple audio files and merges them into a single MP3 using FFmpeg.

## Features

- Merges multiple audio files in order (sorted by field name)
- Returns merged MP3 file
- Docker-ready with health checks
- Designed to work alongside n8n in Docker

---

## Quick Start (Docker)

### Option 1: Connect to existing n8n Docker network

If your n8n is already running in Docker, find its network and connect:

```bash
# 1. Find your n8n container's network
docker inspect <n8n-container-name> | grep -A 5 "Networks"

# 2. Build and run n8n-ffmpeg on the same network
cd /path/to/n8n-ffmpeg

docker build -t n8n-ffmpeg .

docker run -d \
  --name n8n-ffmpeg \
  --network <n8n-network-name> \
  --restart unless-stopped \
  -p 3456:3456 \
  n8n-ffmpeg
```

**In your n8n workflow**, use: `http://n8n-ffmpeg:3456/merge`

### Option 2: Using docker-compose (recommended)

```bash
# 1. First, create the network if it doesn't exist
docker network create n8n_network

# 2. Make sure your n8n container is on this network
docker network connect n8n_network <n8n-container-name>

# 3. Start n8n-ffmpeg
cd /path/to/n8n-ffmpeg
docker-compose up -d
```

**In your n8n workflow**, use: `http://n8n-ffmpeg:3456/merge`

### Option 3: Standalone (localhost access only)

```bash
docker build -t n8n-ffmpeg .

docker run -d \
  --name n8n-ffmpeg \
  --restart unless-stopped \
  -p 3456:3456 \
  n8n-ffmpeg
```

**In your n8n workflow**, use: `http://host.docker.internal:3456/merge` (if n8n is in Docker)
or `http://localhost:3456/merge` (if n8n is running natively)

---

## Local Development (without Docker)

### Prerequisites

- Node.js 18+
- FFmpeg installed (`brew install ffmpeg` on Mac, `apt install ffmpeg` on Ubuntu)

### Setup

```bash
cd n8n-ffmpeg
npm install
npm start
```

Server runs on `http://localhost:3456`

---

## API Reference

### Health Check

```
GET /health
```

Response:
```json
{"status": "ok", "service": "n8n-ffmpeg"}
```

### Merge Audio Files

```
POST /merge
Content-Type: multipart/form-data
```

**Parameters:**
- `audio_0`, `audio_1`, `audio_2`, ... (binary audio files, sorted by number)

**Response:**
- `Content-Type: audio/mpeg`
- Binary MP3 file

**Example with curl:**
```bash
curl -X POST http://localhost:3456/merge \
  -F "audio_0=@segment1.mp3" \
  -F "audio_1=@segment2.mp3" \
  -F "audio_2=@segment3.mp3" \
  --output merged.mp3
```

---

## n8n Workflow Configuration

### HTTP Request Node Settings

| Setting | Value |
|---------|-------|
| Method | POST |
| URL | `http://n8n-ffmpeg:3456/merge` (Docker) or `http://localhost:3456/merge` (local) |
| Body Content Type | Multipart Form Data |
| Send Binary Data | Yes |
| Binary Property | `audio_0,audio_1,audio_2,audio_3,audio_4,audio_5,audio_6,audio_7` |
| Response Format | File |

---

## Troubleshooting

### Container can't connect to n8n-ffmpeg

1. Check if both containers are on the same network:
   ```bash
   docker network inspect <network-name>
   ```

2. Verify n8n-ffmpeg is running:
   ```bash
   docker ps | grep n8n-ffmpeg
   docker logs n8n-ffmpeg
   ```

3. Test connectivity from n8n container:
   ```bash
   docker exec -it <n8n-container> wget -qO- http://n8n-ffmpeg:3456/health
   ```

### FFmpeg merge fails

1. Check logs:
   ```bash
   docker logs n8n-ffmpeg
   ```

2. Ensure audio files are valid MP3/audio format

3. Check temp directory permissions:
   ```bash
   docker exec -it n8n-ffmpeg ls -la /app/temp
   ```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3456` | Server port |

---

## License

MIT
