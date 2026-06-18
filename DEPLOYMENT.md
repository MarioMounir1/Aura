# 🚀 Deployment Guide

This guide covers deploying the Autonomous AI Nutrition Engine to production.

---

## 📋 Pre-Deployment Checklist

- [ ] All environment variables configured (`.env`)
- [ ] Database is production-grade PostgreSQL with backups
- [ ] Gemini API key is valid and has sufficient quota
- [ ] TypeScript builds without errors: `npm run build`
- [ ] All tests pass
- [ ] Database migrations applied: `npm run db:push`
- [ ] Initial seed data loaded (optional): `npm run db:seed`

---

## 🏗️ Option 1: Deploy to Vercel (Recommended for Quick Start)

Vercel handles Node.js + PostgreSQL well and has built-in monitoring.

### Setup

1. **Create Vercel account** at [vercel.com](https://vercel.com)

2. **Connect your repository** (GitHub, GitLab, or Bitbucket)

3. **Configure environment variables** in Vercel dashboard:
   ```
   DATABASE_URL=postgresql://...
   GEMINI_API_KEY=your-key-here
   NODE_ENV=production
   ```

4. **Deploy**:
   ```bash
   npm install -g vercel
   vercel
   ```

5. **Run migrations on Vercel**:
   ```bash
   vercel env pull    # Pull Vercel .env.production.local
   npm run db:push    # Apply migrations to production DB
   ```

---

## 🐳 Option 2: Docker + Container Registry

### Dockerfile

Create `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source and build
COPY . .
RUN npm run build

# Generate Prisma client
RUN npx prisma generate

# Expose port
EXPOSE 3000

# Run migrations and start
CMD ["sh", "-c", "npx prisma db push && npm start"]
```

### .dockerignore

```
node_modules
dist
.env
.git
.gitignore
README.md
```

### Build & Push

```bash
# Build image
docker build -t nutrition-engine:latest .

# Tag for registry (e.g., Docker Hub)
docker tag nutrition-engine:latest yourregistry/nutrition-engine:latest

# Push
docker push yourregistry/nutrition-engine:latest
```

### Run Container

```bash
docker run -e DATABASE_URL="postgresql://..." \
           -e GEMINI_API_KEY="your-key" \
           -p 3000:3000 \
           yourregistry/nutrition-engine:latest
```

---

## ☁️ Option 3: Railway (Simple PaaS)

### Steps

1. **Sign up** at [railway.app](https://railway.app)

2. **Connect GitHub repo**

3. **Add PostgreSQL plugin** from Railway dashboard

4. **Set environment variables**:
   ```
   DATABASE_URL=railway-provided-url
   GEMINI_API_KEY=your-key
   NODE_ENV=production
   ```

5. **Deploy**: Push to main branch (automatic)

---

## 📊 Option 4: AWS EC2 + RDS

### Database (RDS)

```bash
# Create RDS PostgreSQL instance via AWS Console
# - Engine: PostgreSQL 15+
# - Multi-AZ for high availability
# - Automated backups enabled
# - Publicly accessible (for app server)
```

### App Server (EC2)

```bash
# SSH into EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clone repository
git clone https://github.com/your-repo/nutrition-engine.git
cd nutrition-engine

# Install dependencies
npm ci

# Configure environment
nano .env
# DATABASE_URL=postgresql://user:pass@rds-endpoint:5432/nutrition_engine
# GEMINI_API_KEY=your-key
# NODE_ENV=production

# Run migrations
npm run db:push

# Start with PM2 (process manager)
npm install -g pm2
pm2 start npm --name "nutrition-engine" -- start
pm2 save
pm2 startup
```

---

## 🔐 Security Best Practices

### Environment Variables

- **Never commit `.env` files** to version control
- Use `.env.example` as template
- Rotate API keys regularly
- Use secrets manager (Vercel Secrets, AWS Secrets Manager, etc.)

### Database

- Enable SSL for database connections
- Use strong passwords (20+ characters)
- Enable backups and point-in-time recovery
- Restrict database access to application IP only
- Run regular security patches

### API

- Enable HTTPS only (redirect HTTP to HTTPS)
- Add rate limiting (prevent abuse):
  ```typescript
  import rateLimit from 'express-rate-limit';
  
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100                     // 100 requests per IP
  });
  
  app.use('/api/', limiter);
  ```
- Monitor API usage and quota

### Monitoring

- Set up error tracking (Sentry, Rollbar, etc.)
- Monitor database performance
- Alert on high API costs
- Log all requests to aggregation service (CloudWatch, DataDog, etc.)

---

## 📈 Scaling Considerations

### Horizontal Scaling

Multiple instances can share the same database:

```
Load Balancer
    ├─ App Instance 1
    ├─ App Instance 2
    └─ App Instance 3
         ↓
    Shared PostgreSQL Database
```

Since the cache lives in the database, all instances benefit from cached data.

### Database Optimization

```sql
-- Create index for faster lookups
CREATE INDEX idx_cached_menu_item_lookup 
ON "CachedMenuItem"(restaurantId, itemName);
```

### Read Replicas

For read-heavy workloads:

```typescript
// Configure Prisma with read replicas
// (Requires custom logic in PrismaClient setup)
```

### Caching Layer (Redis - Optional)

Add Redis for even faster cache hits (avoid DB roundtrip):

```typescript
import redis from 'redis';

const client = redis.createClient();

// Check Redis first
const cached = await client.get(`${restaurantId}:${itemName}`);
if (cached) return JSON.parse(cached);

// Fall back to database
const dbResult = await prisma.cachedMenuItem.findUnique(...);
await client.setEx(`${restaurantId}:${itemName}`, 86400, JSON.stringify(dbResult));
```

---

## 📊 Monitoring & Alerts

### Key Metrics

- Request latency (target: <100ms for cache hits, <2s for misses)
- Error rate (target: <0.5%)
- Cache hit ratio (target: >80% after warmup)
- API cost per request (should decrease as cache fills)
- Database storage growth

### Example CloudWatch Dashboard

```
Dashboard: Nutrition Engine Production
├─ Requests per minute
├─ Cache hit ratio
├─ Average response time
├─ Error rate
├─ Gemini API cost
└─ Database size
```

---

## 🔄 CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      
      - run: npm ci
      - run: npm run build
      - run: npm test  # Add tests
      
      - name: Deploy to Vercel
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
        run: vercel --prod
```

---

## 🆘 Rollback Procedure

If deployment fails:

```bash
# Revert to previous version
git revert HEAD
git push origin main

# Or switch to previous Vercel deployment:
# Vercel dashboard → Deployments → Previous version → Promote
```

---

## 📞 Support & Troubleshooting

### Database Connection Issues

```bash
# Test connection
psql "postgresql://user:pass@host:5432/database"

# Check database logs
# AWS RDS → Instance → Logs
# Railway → Database → Logs
```

### High Gemini API Costs

- Check for repeated cache misses (indicates ineffective caching)
- Monitor batch request usage (ensure efficient processing)
- Add request logging to identify problematic items

### Slow Response Times

```bash
# Check database query performance
npm run db:studio

# Monitor slow query logs
SELECT query_start, query 
FROM pg_stat_statements 
WHERE mean_time > 1000 
ORDER BY mean_time DESC;
```

---

## 🎯 Summary

| Aspect | Recommendation |
|--------|-----------------|
| **Database** | PostgreSQL 15+ with automated backups |
| **Hosting** | Vercel (simplest) or Railway (good balance) |
| **Monitoring** | Sentry for errors, CloudWatch for metrics |
| **Rate Limiting** | 100 req/IP/15min minimum |
| **SSL** | Required (HTTPS only) |
| **API Keys** | Rotated every 90 days |
| **Backup** | Daily, with 30-day retention |

---

Good luck with your deployment! 🚀
