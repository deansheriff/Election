FROM node:18-alpine
WORKDIR /app

# Build context is repo root (docker-compose.yaml sets context: .)
COPY voteng_api/package*.json ./
RUN npm install --production

COPY voteng_api/ .

EXPOSE 3000

CMD ["npm", "start"]
