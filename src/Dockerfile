# Build stage
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && \
    npm cache clean --force
COPY . .

# Production stage
FROM node:18-alpine

WORKDIR /app
COPY --from=build /app /app

RUN adduser -D goldenowl && \
    chown -R goldenowl:goldenowl /app

USER goldenowl

EXPOSE 3000

CMD ["npm", "start"]
