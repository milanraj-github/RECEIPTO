FROM node:22-bookworm-slim

# Install Chromium and all required runtime dependencies for Puppeteer headless Chrome
RUN apt-get update && apt-get install -y --no-install-recommends \
    chromium \
    ca-certificates \
    fonts-freefont-ttf \
    fonts-liberation \
    fonts-ipafont-gothic \
    fonts-wqy-zenhei \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    procps \
    xdg-utils \
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

# Start WhatsApp Bot with memory heap capped for 512MB RAM cloud tiers
CMD ["node", "--max-old-space-size=192", "bot.js"]
