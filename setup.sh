#!/bin/bash

# n8n-ffmpeg Setup Script
# Automatically connects to your running n8n Docker container's network

set -e

echo "🔍 Looking for n8n container..."

# Find n8n container
N8N_CONTAINER=$(docker ps --format '{{.Names}}' | grep -i n8n | head -1)

if [ -z "$N8N_CONTAINER" ]; then
    echo "❌ No running n8n container found."
    echo ""
    echo "Options:"
    echo "  1. Start your n8n container first, then run this script again"
    echo "  2. Run standalone: docker-compose up -d"
    echo ""
    exit 1
fi

echo "✅ Found n8n container: $N8N_CONTAINER"

# Get the network
N8N_NETWORK=$(docker inspect "$N8N_CONTAINER" --format '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}{{end}}' | head -1)

if [ -z "$N8N_NETWORK" ]; then
    echo "❌ Could not determine n8n network"
    exit 1
fi

echo "✅ n8n is on network: $N8N_NETWORK"

# Build the image
echo ""
echo "🔨 Building n8n-ffmpeg image..."
docker build -t n8n-ffmpeg .

# Stop existing container if running
if docker ps -a --format '{{.Names}}' | grep -q '^n8n-ffmpeg$'; then
    echo "🛑 Stopping existing n8n-ffmpeg container..."
    docker stop n8n-ffmpeg 2>/dev/null || true
    docker rm n8n-ffmpeg 2>/dev/null || true
fi

# Run the container on the same network
echo ""
echo "🚀 Starting n8n-ffmpeg on network: $N8N_NETWORK"
docker run -d \
    --name n8n-ffmpeg \
    --network "$N8N_NETWORK" \
    --restart unless-stopped \
    -p 3456:3456 \
    n8n-ffmpeg

# Wait for health check
echo ""
echo "⏳ Waiting for server to be ready..."
sleep 3

# Verify it's running
if docker exec n8n-ffmpeg wget -qO- http://localhost:3456/health > /dev/null 2>&1; then
    echo ""
    echo "✅ n8n-ffmpeg is running!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Use this URL in your n8n workflow:"
    echo ""
    echo "   http://n8n-ffmpeg:3456/merge"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "⚠️  Container started but health check failed. Check logs:"
    echo "   docker logs n8n-ffmpeg"
fi
