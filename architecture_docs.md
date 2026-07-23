# System Architecture Documentation

## Executive Summary

**Deliofresh Medusa DTC Starter** is an enterprise-grade, direct-to-consumer (DTC) e-commerce solution built as a high-performance monorepo using **pnpm v10** and **Turborepo**.

The system decouples the e-commerce engine from the frontend:
- **Headless Backend**: Medusa v2 framework providing product management, region handling, cart workflows, checkout processing, order management, customer accounts, and an embedded Admin UI.
- **Storefront**: Next.js 15 app built on React 19 and Tailwind CSS, utilizing Server Components and Server Actions for optimal performance and SEO.
- **Persistence Layer**: PostgreSQL v15+ as primary datastore and Redis v7+ for event bus, job queueing, and caching.

---

## High-Level System Architecture

```mermaid
graph TD
    Client["Client / Web Browser"]
    
    subgraph ReverseProxy["Dokploy Traefik Reverse Proxy"]
        HTTPS_Store["https://shop.yourdomain.com"]
        HTTPS_API["https://api.yourdomain.com"]
    end

    subgraph ApplicationLayer["Docker Application Containers"]
        SF["Storefront App (Next.js 15)<br/>Container Port: 3000"]
        BE["Medusa v2 Backend<br/>Container Port: 9000"]
        Admin["Medusa Admin Dashboard<br/>Served at /app"]
    end

    subgraph DatabaseLayer["Managed Database Services"]
        PG[("PostgreSQL 15+<br/>Container Port: 5432")]
        RD[("Redis 7+<br/>Container Port: 6379")]
    end

    Client -->|HTTPS Traffic| HTTPS_Store
    Client -->|HTTPS Traffic| HTTPS_API
    
    HTTPS_Store --> SF
    HTTPS_API --> BE
    HTTPS_API --> Admin

    SF -->|REST API / Storefront SDK| BE
    BE -->|SQL Queries / Migrations| PG
    BE -->|Event Bus & Cache| RD
```

---

## Workspace Directory & Monorepo Index

```
deliofresh-medusa/
├── apps/
│   ├── backend/                      # @dtc/backend (Medusa v2 Framework)
│   │   ├── src/                      # Custom modules, API routes, subscribers & workflows
│   │   │   ├── admin/                # Custom Medusa Admin extensions & widgets
│   │   │   ├── api/                  # Custom REST API endpoints
│   │   │   ├── jobs/                 # Scheduled background jobs
│   │   │   ├── modules/              # Custom Medusa core modules
│   │   │   └── workflows/            # Medusa v2 execution workflows
│   │   ├── medusa-config.ts          # Medusa configuration (Database, CORS, Secrets)
│   │   ├── instrumentation.ts        # Telemetry & startup hooks
│   │   ├── package.json              # Backend dependencies
│   │   └── tsconfig.json             # TypeScript configuration
│   │
│   └── storefront/                   # @dtc/storefront (Next.js 15 Storefront)
│       ├── src/                      # App router pages, UI components, data loaders
│       │   ├── app/                  # Next.js App Router ([countryCode]/routes)
│       │   ├── lib/                  # Medusa JS SDK client, data fetching helpers
│       │   └── modules/              # Layout, product, cart, checkout UI modules
│       ├── check-env-variables.js    # Build-time environment sanity checker
│       ├── next.config.js            # Next.js configuration (Standalone mode)
│       ├── tailwind.config.js        # Design tokens & styling configuration
│       └── package.json              # Storefront dependencies
│
├── .npmrc                            # pnpm settings
├── package.json                      # Root workspace scripts & Turborepo configuration
├── pnpm-workspace.yaml               # pnpm workspace definition (apps/*)
├── turbo.json                        # Turborepo build & dev task graph
├── README.md                         # Project setup & developer guide
├── Dockerfile.backend                # Container build spec for Medusa v2 Backend
├── Dockerfile.storefront             # Container build spec for Next.js Storefront
├── docker-compose.yml                # Docker Compose orchestration
└── DEPLOYMENT_GUIDE.md               # Dokploy deployment steps & task guide
```

---

## Service Specifications

### 1. Medusa Backend (`@dtc/backend`)
- **Framework**: Medusa v2 Framework (`@medusajs/framework` v2.17, `@medusajs/medusa` v2.17)
- **Runtime**: Node.js >= 20.x
- **Container Port**: `9000`
- **Key Modules**:
  - Store API: Handles public storefront requests (`/store/*`).
  - Admin Dashboard: Embedded admin application at `/app`.
  - Auth Module: Manages JWT and session-based authentication for customers and admin users.
  - Payment Integration: Supports Stripe and manual payment providers.

### 2. Next.js Storefront (`@dtc/storefront`)
- **Framework**: Next.js 15.5.18 (React 19, Tailwind CSS)
- **Runtime**: Node.js >= 20.x (Standalone Server)
- **Container Port**: `3000`
- **Key Capabilities**:
  - Dynamic localized routing based on country code (e.g. `/dk`, `/us`).
  - Server-side rendering (SSR) and Incremental Static Regeneration (ISR) for fast product listing pages.
  - Cart, promotion codes, and multi-step checkout integration.
  - User account management, address books, and order history.

---

## Environment Variables Matrix

### Backend Environment Variables (`apps/backend/.env`)

| Variable | Type | Description | Example / Default |
| :--- | :--- | :--- | :--- |
| `DATABASE_URL` | String (Required) | PostgreSQL connection string | `postgres://postgres:password@postgres:5432/medusa-dtc-starter` |
| `REDIS_URL` | String (Optional) | Redis server URL for cache/event bus | `redis://redis:6379` |
| `JWT_SECRET` | Secret (Required) | Secret key for signing JWT tokens | `supersecret` |
| `COOKIE_SECRET` | Secret (Required) | Secret key for signing cookies | `supersecret` |
| `STORE_CORS` | String (Required) | Allowed origins for storefront CORS | `https://shop.yourdomain.com` |
| `ADMIN_CORS` | String (Required) | Allowed origins for admin CORS | `https://api.yourdomain.com` |
| `AUTH_CORS` | String (Required) | Allowed origins for auth endpoints | `https://shop.yourdomain.com,https://api.yourdomain.com` |

### Storefront Environment Variables (`apps/storefront/.env.local`)

| Variable | Type | Scope | Description | Example / Default |
| :--- | :--- | :--- | :--- | :--- |
| `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY` | String (Required) | Build & Runtime | Publishable API Key generated in Medusa Admin | `pk_6c3...` |
| `NEXT_PUBLIC_MEDUSA_BACKEND_URL` | URL (Required) | Build & Runtime | Absolute public URL of Medusa Backend | `https://api.yourdomain.com` |
| `NEXT_PUBLIC_DEFAULT_REGION` | String (Required) | Build & Runtime | Default region country code | `dk` |
| `NEXT_PUBLIC_BASE_URL` | URL (Required) | Build & Runtime | Public base URL of Storefront | `https://shop.yourdomain.com` |
| `NEXT_PUBLIC_STRIPE_KEY` | String (Optional) | Build & Runtime | Stripe publishable key | `pk_test_...` |
| `NODE_ENV` | String (Required) | Runtime | Node execution environment | `production` |

---

## Security & Network Topology

1. **CORS Isolation**: The Backend strictly validates cross-origin requests using `STORE_CORS`, `ADMIN_CORS`, and `AUTH_CORS`.
2. **Reverse Proxy & SSL**: In Dokploy, Traefik acts as the edge reverse proxy, managing automatic Let's Encrypt TLS/SSL certificates and proxying requests to internal container ports (`9000` for backend, `3000` for storefront).
3. **Database Isolation**: PostgreSQL and Redis services reside on internal Docker bridge networks, unreachable from the public internet.
