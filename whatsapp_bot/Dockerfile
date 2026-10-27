FROM node:22-bookworm-slim

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
