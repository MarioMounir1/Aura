# ============================================================
#  Dockerfile — Aura Node.js API + Aura Athletics Web App
#  Multi-stage build (context = repo root):
#    1. Build Vite React web app (web/)
#    2. Compile Express TypeScript API (backend/)
#    3. Lean production image serving both API and Web SPA
# ============================================================

# ── Stage 1: Web Builder ──────────────────────────────────
FROM node:22-alpine AS web-builder

WORKDIR /web

COPY web/package*.json ./
RUN npm ci

COPY web/ ./
RUN npm run build

# ── Stage 2: API Builder ──────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies (including devDependencies for tsc)
COPY backend/package*.json ./
RUN npm ci

# Copy source and compile TypeScript
COPY backend/tsconfig.json ./
COPY backend/prisma.config.ts ./
COPY backend/prisma ./prisma/
COPY backend/src ./src/

# Generate Prisma client
RUN npx prisma generate

# Compile TypeScript → JavaScript
RUN npm run build

# ── Stage 3: Production ───────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

# Install only production dependencies
COPY backend/package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled API output and Prisma client
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
COPY backend/prisma.config.ts ./
COPY backend/prisma ./prisma/

# Copy compiled Aura Athletics web bundle (/web/dist matches ../../web/dist from /app/dist)
COPY --from=web-builder /web/dist /web/dist

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 calcuser && \
    chown -R calcuser:nodejs /app /web/dist

USER calcuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "dist/app.js"]
