# Build stage
FROM node:18-alpine AS build

WORKDIR /app
COPY package*.json ./

ARG NODE_ENV=production
ENV NODE_ENV=$NODE_ENV

RUN if [ "$NODE_ENV" = "production" ]; then \
      npm ci --omit=dev; \
    else \
      npm ci; \
    fi && \
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

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["npm", "start"]
