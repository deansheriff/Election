FROM node:18-alpine
WORKDIR /app

# Build context is voteng_api/ (Coolify sends the subdirectory as context)
COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
