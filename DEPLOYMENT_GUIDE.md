# Dokploy & Docker Deployment Guide

This guide provides step-by-step instructions and a principal engineering task list to deploy the **Deliofresh Medusa DTC Starter** monorepo to **Dokploy** using Docker containers.

---

## 📋 Deployment Checklist & Task List

### Phase 1: Pre-Deployment Readiness
- [x] Create project architecture documentation (`architecture_docs.md`).
- [x] Configure Next.js standalone output mode in `apps/storefront/next.config.js`.
- [x] Create backend multi-stage Dockerfile (`Dockerfile.backend`).
- [x] Create storefront multi-stage Dockerfile (`Dockerfile.storefront`).
- [x] Create Docker Compose specification (`docker-compose.yml`).
- [ ] Push code changes to Git repository (GitHub / GitLab).
- [ ] Prepare production domain names (e.g. `shop.yourdomain.com` and `api.yourdomain.com`).

### Phase 2: Dokploy Database Provisioning
- [ ] Create Dokploy Project (`Deliofresh Medusa`).
- [ ] Provision PostgreSQL Database service (`medusa-dtc-starter`).
- [ ] Provision Redis service for event bus and caching.
- [ ] Save database internal connection strings for backend environment setup.

### Phase 3: Backend Deployment & Initialization
- [ ] Create Dokploy Application (`medusa-backend`).
- [ ] Configure Git repository, branch, and Dockerfile path (`./Dockerfile.backend`).
- [ ] Configure Environment Variables (`DATABASE_URL`, `REDIS_URL`, `JWT_SECRET`, `COOKIE_SECRET`, `STORE_CORS`, `ADMIN_CORS`, `AUTH_CORS`).
- [ ] Deploy backend container (runs automatic `medusa db:migrate`).
- [ ] Map custom domain (`api.yourdomain.com`) with HTTPS enabled.
- [ ] Exec into backend container terminal and create superadmin user (`pnpm medusa user -e admin@yourdomain.com -p <password>`).
- [ ] Log into Medusa Admin dashboard (`https://api.yourdomain.com/app`) and create a **Publishable API Key**.

### Phase 4: Storefront Deployment
- [ ] Create Dokploy Application (`medusa-storefront`).
- [ ] Configure Git repository, branch, and Dockerfile path (`./Dockerfile.storefront`).
- [ ] Set **Build Arguments (`ARG`)** and Environment Variables:
  - `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`: *(From Phase 3)*
  - `NEXT_PUBLIC_MEDUSA_BACKEND_URL`: `https://api.yourdomain.com`
  - `NEXT_PUBLIC_BASE_URL`: `https://shop.yourdomain.com`
  - `NEXT_PUBLIC_DEFAULT_REGION`: `dk` (or preferred country code)
- [ ] Set Container Port to `3000`.
- [ ] Deploy storefront container.
- [ ] Map custom domain (`shop.yourdomain.com`) with HTTPS enabled.

### Phase 5: Verification & E2E Testing
- [ ] Verify storefront home page loads at `https://shop.yourdomain.com`.
- [ ] Test product catalog, region selector, cart addition, and checkout flow.
- [ ] Verify CORS headers between Storefront and Backend.

---

## 🚀 Step-by-Step Dokploy Setup Guide

### Step 1: Create Project & Provision Databases in Dokploy

1. Open your Dokploy instance dashboard.
2. Click **Projects** -> **Create Project** -> Name: `Deliofresh Medusa`.
3. Add **PostgreSQL Database**:
   - Name: `deliofresh-postgres`
   - Database Name: `medusa-dtc-starter`
   - Username: `postgres`
   - Password: `<generate-strong-password>`
   - Internal Host/IP: Note the internal Docker container name assigned by Dokploy.
   - **Internal Connection String**: `postgres://postgres:<password>@deliofresh-postgres:5432/medusa-dtc-starter`
4. Add **Redis Database**:
   - Name: `deliofresh-redis`
   - **Internal Connection String**: `redis://deliofresh-redis:6379`

---

### Step 2: Deploy Medusa Backend Application

1. Inside your Dokploy project, click **Create Application**.
2. Name: `medusa-backend`.
3. **Source Setup**:
   - Provider: Git (GitHub / GitLab)
   - Repository: `your-org/deliofresh-medusa`
   - Branch: `main`
4. **Build Configuration**:
   - Build Type: **Dockerfile**
   - Dockerfile Path: `./Dockerfile.backend`
5. **Environment Variables**:
   Add the following variables in Dokploy:
   ```env
   NODE_ENV=production
   PORT=9000
   DATABASE_URL=postgres://postgres:<password>@deliofresh-postgres:5432/medusa-dtc-starter
   REDIS_URL=redis://deliofresh-redis:6379
   JWT_SECRET=<generate-random-32-byte-hex>
   COOKIE_SECRET=<generate-random-32-byte-hex>
   STORE_CORS=https://shop.yourdomain.com
   ADMIN_CORS=https://api.yourdomain.com
   AUTH_CORS=https://shop.yourdomain.com,https://api.yourdomain.com
   ```
6. **Domains & Ports**:
   - App Port: `9000`
   - Host: `api.yourdomain.com`
   - HTTPS: Enabled (Traefik automatically provisions SSL certificate via Let's Encrypt).
7. Click **Deploy**.

---

### Step 3: Initialize Database & Admin User

Once the backend container status shows **Running**:

1. Click on the `medusa-backend` application in Dokploy.
2. Go to the **Terminal / Exec** tab.
3. Run the admin creation command:
   ```bash
   pnpm medusa user -e admin@yourdomain.com -p "YourStrongPassword123!"
   ```
4. Open `https://api.yourdomain.com/app` in your browser.
5. Log in with `admin@yourdomain.com` and your password.
6. Navigate to **Settings** -> **Publishable API Keys**.
7. Create a key named `Storefront Key` and copy its value (e.g. `pk_01HJ...`).

---

### Step 4: Deploy Next.js Storefront Application

1. In Dokploy, click **Create Application**.
2. Name: `medusa-storefront`.
3. **Source Setup**:
   - Provider: Git
   - Repository: `your-org/deliofresh-medusa`
   - Branch: `main`
4. **Build Configuration**:
   - Build Type: **Dockerfile**
   - Dockerfile Path: `./Dockerfile.storefront`
5. **Build Arguments (`ARG`) & Environment Variables**:
   In Dokploy Environment Settings, populate both Environment & Build Arguments:
   ```env
   NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_01HJ... (Copied from Step 3)
   NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.yourdomain.com
   NEXT_PUBLIC_BASE_URL=https://shop.yourdomain.com
   NEXT_PUBLIC_DEFAULT_REGION=dk
   ```
6. **Domains & Ports**:
   - App Port: `3000`
   - Host: `shop.yourdomain.com`
   - HTTPS: Enabled
7. Click **Deploy**.

---

## 🐳 Alternative Deployment: Dokploy Compose

If you prefer deploying the entire stack via Docker Compose:

1. In Dokploy, click **Create Compose Application**.
2. Name: `deliofresh-monorepo`.
3. Source: Point to Git repo `main` branch or paste contents of `docker-compose.yml`.
4. Define Environment Variables:
   ```env
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=supersecurepassword
   POSTGRES_DB=medusa-dtc-starter
   NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=pk_01HJ...
   NEXT_PUBLIC_MEDUSA_BACKEND_URL=https://api.yourdomain.com
   NEXT_PUBLIC_BASE_URL=https://shop.yourdomain.com
   JWT_SECRET=supersecret_jwt_token
   COOKIE_SECRET=supersecret_cookie_secret
   STORE_CORS=https://shop.yourdomain.com
   ADMIN_CORS=https://api.yourdomain.com
   AUTH_CORS=https://shop.yourdomain.com,https://api.yourdomain.com
   ```
5. Click **Deploy Compose**.

---

## 🛠️ Post-Deployment Maintenance & Operations

### Viewing Container Logs
In Dokploy, select any application or database service and navigate to the **Logs** tab for real-time stdout/stderr log streams.

### Database Backups
In Dokploy, select the PostgreSQL service -> **Backups** tab -> Configure automated daily S3 or local disk backups.

### Updating Environment Variables
When updating `NEXT_PUBLIC_` variables for the Storefront, trigger a fresh **Rebuild** in Dokploy so Next.js bakes the new build arguments into the static bundles.
