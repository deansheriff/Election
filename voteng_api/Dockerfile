FROM node:18-alpine
WORKDIR /app

# Build context is the project root, so paths are relative to that
COPY voteng_api/package*.json ./
RUN npm install --production

COPY voteng_api/ .
# Bundle the DB scripts so db-init.js can apply them if the volume is stale/empty
COPY database/ ./database/

EXPOSE 3000

CMD ["npm", "start"]
