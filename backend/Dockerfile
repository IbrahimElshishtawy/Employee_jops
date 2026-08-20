# Stage 1: Build & Dependencies
FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

COPY . .

RUN npx prisma generate
RUN npm run build
RUN npm prune --production

# Stage 2: Production Container
FROM node:20-alpine AS production

WORKDIR /usr/src/app

ENV NODE_ENV=production

# Copy build artifacts with appropriate ownership
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=builder /usr/src/app/dist ./dist
COPY --chown=node:node --from=builder /usr/src/app/prisma ./prisma
COPY --chown=node:node --from=builder /usr/src/app/package*.json ./

# Security: Run as non-root user
USER node

EXPOSE 3000

CMD ["node", "dist/main"]
