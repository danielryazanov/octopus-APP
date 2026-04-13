# 🐙 Octopus App

> A production-grade "Hello World" web application that displays fruit inventory from MongoDB, built on a fully containerised, secure, monitored, and CI/CD-automated architecture.

---

## 📐 Architecture Overview

```
                     ┌─────────────────────────────────────────────────┐
   Internet          │                  Docker Host                     │
 ──────────►  80     │                                                  │
                     │  ┌──────────────────────────────────────────┐   │
                     │  │          Nginx (Load Balancer)           │   │
                     │  │     Round-robin across app replicas      │   │
                     │  └────────┬──────────────┬──────────────────┘   │
                     │           │              │                       │
                     │  ┌────────▼───┐  ┌───────▼────┐                │
                     │  │ app:3000   │  │ app:3000   │  (2-3 replicas) │
                     │  │  NodeJS    │  │  NodeJS    │                  │
                     │  │  Express   │  │  Express   │                  │
                     │  └────────┬───┘  └───────┬────┘                │
                     │           └──────┬────────┘                     │
                     │                  ▼                               │
                     │          ┌──────────────┐                       │
                     │          │  MongoDB 7   │                       │
                     │          │  (internal)  │                       │
                     │          └──────────────┘                       │
                     │                                                  │
                     │  ┌──────────────┐   ┌──────────────┐           │
                     │  │  Prometheus  │   │   Grafana    │           │
                     │  │   :9090      │   │    :3001     │           │
                     │  └──────────────┘   └──────────────┘           │
                     └─────────────────────────────────────────────────┘
```

### Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Web App** | Node.js 18 + Express | REST API + HTML UI |
| **Database** | MongoDB 7 | Persistent fruit data |
| **Load Balancer** | Nginx 1.25 | Reverse proxy, rate limiting, security headers |
| **Monitoring** | Prometheus 2.48 | Metrics scraping & storage |
| **Dashboards** | Grafana 10.2 | Visual monitoring dashboards |
| **Containers** | Docker + Compose | All services containerised |
| **CI/CD** | GitHub Actions | Automated lint → test → build → deploy |

---

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) ≥ 24.x
- [Docker Compose](https://docs.docker.com/compose/install/) ≥ 2.x
- `curl`, `bash`

### 1. Clone the repository

```bash
git clone https://github.com/danielryazanov/octopus-APP.git
cd octopus-APP
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env and set strong passwords
nano .env
```

### 3. Provision everything

```bash
./scripts/provision.sh
```

This script will:
1. Check Docker / Docker Compose availability
2. Build all images
3. Start all services in the correct dependency order
4. Wait for health checks to pass
5. Run a smoke test to verify apples quantity = 5

### 4. Access the application

| Service | URL |
|---------|-----|
| 🌐 Web App | http://localhost |
| 🔌 API | http://localhost/api/fruits |
| 📊 Prometheus | http://localhost:9090 |
| 📈 Grafana | http://localhost:3001 |

---

## 🌍 What You'll See

The homepage displays:

- **Number of apples in stock** (queried live from MongoDB) – `5`
- A table with all fruits:

| # | Fruit | Qty | Rating | Extra |
|---|-------|-----|--------|-------|
| 1 | apples | 5 | ⭐⭐⭐ | — |
| 2 | bananas | 7 | ⭐ | ☢ 0.1 µSv |
| 3 | oranges | 6 | ⭐⭐ | — |
| 4 | avocados | 3 | ⭐⭐⭐⭐⭐ | — |

---

## 🗂️ Repository Structure

```
octopus-APP/
├── app/                        # NodeJS application
│   ├── src/
│   │   ├── index.js            # Express server entry point
│   │   ├── models/
│   │   │   └── Fruit.js        # Mongoose model
│   │   ├── routes/
│   │   │   ├── fruits.js       # /api/fruits routes
│   │   │   └── metrics.js      # /metrics Prometheus endpoint
│   │   ├── public/
│   │   │   └── index.html      # Frontend HTML page
│   │   └── __tests__/
│   │       └── app.test.js     # Jest integration tests
│   ├── Dockerfile
│   ├── package.json
│   └── .eslintrc.js
├── nginx/
│   ├── nginx.conf              # Reverse proxy + security headers + rate limiting
│   └── Dockerfile
├── mongo-init/
│   └── init.js                 # DB seed script (runs on first start)
├── prometheus/
│   └── prometheus.yml          # Scrape configuration
├── grafana/
│   └── provisioning/
│       ├── datasources/        # Auto-configured Prometheus data source
│       └── dashboards/         # Auto-provisioned dashboards
├── scripts/
│   ├── provision.sh            # Full infrastructure provisioning script
│   └── teardown.sh             # Tear-down script
├── .github/
│   └── workflows/
│       ├── ci.yml              # CI: lint → test → build → security scan
│       └── cd.yml              # CD: deploy to production via SSH
├── docker-compose.yml          # Dev / staging stack
├── docker-compose.prod.yml     # Production overrides
├── .env.example                # Environment variable template
└── README.md
```

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | HTML frontend |
| GET | `/api/fruits` | List all fruits |
| GET | `/api/fruits/:name` | Get fruit by name |
| GET | `/healthz` | Health check (returns `{"status":"ok"}`) |
| GET | `/metrics` | Prometheus metrics |

---

## 🔄 CI/CD Pipeline (GitHub Actions)

### CI (`.github/workflows/ci.yml`)

Triggered on every push / pull request:

```
Push / PR
    │
    ├── Lint (ESLint)
    ├── Tests (Jest + in-memory MongoDB)
    ├── Build Docker image → push to GHCR
    └── Security scan (Trivy) → upload to GitHub Security tab
```

### CD (`.github/workflows/cd.yml`)

Triggered on push to `main`/`master` or version tags (`v*.*.*`):

```
Push to main / tag
    │
    └── Deploy over SSH
            ├── Pull latest compose files
            ├── Pull new Docker image
            ├── docker compose up -d
            └── Health check smoke test
```

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `DEPLOY_HOST` | SSH host of production server |
| `DEPLOY_USER` | SSH username |
| `DEPLOY_SSH_KEY` | Private SSH key (PEM) |
| `MONGO_ROOT_USER` | MongoDB root username |
| `MONGO_ROOT_PASSWORD` | MongoDB root password |
| `MONGO_APP_USER` | MongoDB app username |
| `MONGO_APP_PASSWORD` | MongoDB app password |
| `GRAFANA_PASSWORD` | Grafana admin password |

---

## 📊 Monitoring (Prometheus + Grafana)

Prometheus scrapes the `/metrics` endpoint on the app every 10 seconds.

### Available metrics

- `http_request_duration_ms` – Histogram of request durations
- `nodejs_heap_size_used_bytes` – Node.js heap usage
- `process_cpu_seconds_total` – CPU usage
- All default `prom-client` Node.js metrics

### Grafana Dashboard

The **Octopus App – Overview** dashboard is auto-provisioned and includes:

- HTTP request rate (req/s) by route
- HTTP latency p95 (ms) by route
- HTTP error rate (5xx/s)
- Node.js heap usage

---

## 🔒 Security Design

### Network Isolation

- **Three separate Docker networks**: `frontend`, `backend`, `monitoring`
- MongoDB is **not reachable from frontend network**
- Prometheus/Grafana metrics are not publicly exposed in production

### Application Hardening

- `helmet.js` – HTTP security headers (CSP, X-Frame-Options, etc.)
- `express-rate-limit` – Rate limiting at application level
- Nginx rate limiting (zone: 30 req/s per IP, burst 50)
- Non-root container user (`appuser`)
- Read-only filesystem in production (`read_only: true`)
- No `root` MongoDB access from the application – uses least-privilege `appuser`

### CI/CD Security

- Trivy container image vulnerability scanning on every build
- SARIF results uploaded to GitHub Security tab
- Secrets managed via GitHub Actions environments (not hardcoded)
- SSH key-based deployment (no passwords)

---

## 🏭 Production Deployment

### Scale application instances

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml \
  up -d --scale app=3
```

### Teardown

```bash
# Stop all services (keep data)
./scripts/teardown.sh

# Stop all services AND delete all data
./scripts/teardown.sh --volumes
```

---

## 🧪 Running Tests Locally

```bash
cd app
npm install
npm test
```

Tests use **Jest with mocked Mongoose** so no running database is required. The mock injects the same fruit data that the MongoDB init script seeds, ensuring test results reflect the real data shape.

---

## 📋 Two-Repository Strategy (Recommended)

For higher security and separation of concerns, use **two GitHub repositories**:

| Repository | Purpose | Access |
|------------|---------|--------|
| `octopus-APP` (this repo) | Source code, IaC, CI | Developers |
| `octopus-APP-deploy` | Deployment configs, secrets, environment | DevOps / Ops team |

The CI pipeline builds and pushes the image; the CD pipeline in the deployment repo pulls and applies it, ensuring developers never have direct access to production credentials.

---

## 👥 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make changes and ensure tests pass: `npm test`
4. Open a Pull Request to `main`

---

## 📄 License

MIT