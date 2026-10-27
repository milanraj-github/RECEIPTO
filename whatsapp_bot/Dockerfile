FROM node:22-bookworm-slim

# Install Chromium and necessary system fonts directly from Debian repositories
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    fonts-freefont-ttf \
    fonts-liberation \
    libnss3 \
    libatk-bridge2.0-0 \
    libxss1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Point Puppeteer to the Debian Chromium binary
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PORT=10000

WORKDIR /app

# Copy package dependencies
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy application files
COPY . .

# Expose health & QR check port
EXPOSE 10000

# Start WhatsApp Bot
CMD ["node", "bot.js"]
