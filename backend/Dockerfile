FROM node:22-bookworm-slim

WORKDIR /app

# Copy package descriptors and install production dependencies
COPY package*.json ./
RUN npm install --omit=dev

# Copy source code
COPY . .

# Cloud standard port
ENV PORT=10000
EXPOSE 10000

CMD ["node", "server.js"]
