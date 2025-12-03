FROM node:20-slim

# Install ffmpeg with full codec support
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy app source
COPY server.js ./

# Create temp directory
RUN mkdir -p /app/temp

# Expose port
EXPOSE 3456

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3456/health || exit 1

# Run the server
CMD ["node", "server.js"]
