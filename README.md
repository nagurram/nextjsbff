# Next.js BFF with IdentityServer

A modern BFF (Backend for Frontend) architecture with:
- **Traefik** — edge load balancer, TLS termination, auto-discovery via Docker labels
- **Next.js 16 BFF** — stateless JWT sessions via NextAuth v4, scalable replicas
- **Duende IdentityServer 10 (.NET 10)** — OIDC/OAuth2 provider

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Browser                           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  Traefik ( :443 )                                              │
│  • TLS termination using certificates/localhost.pem             │
│  • HTTP → HTTPS redirect ( :80 → :443 )                         │
│  • Docker provider auto-discovers BFF replicas                  │
│  • Health checks at /health                                     │
│  • Dashboard at http://localhost:8080                           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP (internal)
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
    ┌─────────┐       ┌─────────┐       ┌─────────┐
    │ BFF #1  │       │ BFF #2  │       │ BFF #3  │
    │ :3000   │       │ :3000   │       │ :3000   │
    └────┬────┘       └────┬────┘       └────┬────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           │ HTTPS
                           ▼
                 ┌───────────────────┐
                 │ IdentityServer    │
                 │ :5001 (internal)  │
                 └───────────────────┘
```

## Quick Start

### Prerequisites
- Docker & Docker Compose v2
- Git

### 1. Clone & Configure Secrets
```bash
git clone https://github.com/nagurram/nextjsbff.git
cd nextjsbff

# Copy example and fill in real secrets
cp .env.docker.example .env.docker
# Edit .env.docker with your values:
# - NEXTAUTH_SECRET (random 32+ char string)
# - IDENTITY_SERVER_CLIENT_SECRET (random string)
```

### 2. Generate Dev Certificates (one-time)
```powershell
# Windows
./scripts/New-LocalDockerCertificate.ps1

# Linux/macOS (manual):
# openssl req -x509 -newkey rsa:4096 -sha256 -days 365 \
#   -nodes -keyout certificates/local-key.pem \
#   -out certificates/local-cert.pem \
#   -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
# # Then combine for Traefik:
# cat certificates/local-cert.pem certificates/local-key.pem > certificates/localhost.pem
```

### 3. Start the Stack
```bash
# Start all services (3 BFF replicas by default)
docker compose up --build

# Or scale BFF replicas differently:
docker compose up --build --scale webapp=5
```

### 4. Access the App
- **BFF**: https://localhost (TLS, Traefik)
- **IdentityServer**: https://localhost:5001 (direct, dev certs)
- **Traefik Dashboard**: http://localhost:8080

## Services

| Service | Port | Description |
|---------|------|-------------|
| `traefik` | 80/443/8080 | Edge LB, TLS, dashboard |
| `webapp` | 3000 (internal) | Next.js BFF (3 replicas by default) |
| `identityserver` | 5001 | Duende IdentityServer |

## Scaling BFF Replicas

### At Startup
```bash
docker compose up --scale webapp=5
```

### Runtime Scaling
```bash
docker compose up --scale webapp=3 -d
# Later:
docker compose up --scale webapp=5 -d
```

The `deploy.replicas: 3` in compose file sets the default. `docker compose up --scale` overrides it.

### How It Works
- **Stateless JWT sessions** (NextAuth `session: { strategy: "jwt" }`) — no sticky sessions needed
- **Traefik passive health checks** probe `/health` every 10s
- **Auto-discovery** via Docker labels — new replicas picked up automatically

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXTAUTH_SECRET` | Random string for JWT signing (32+ chars) | Yes |
| `IDENTITY_SERVER_CLIENT_SECRET` | Client secret for BFF→IdentityServer | Yes |
| `WEBAPP_ORIGIN` | BFF origin for IdentityServer redirect URIs | Default: `https://localhost` |
| `IDENTITY_SERVER_PORT` | IdentityServer HTTPS port | Default: `5001` |

## Certificates

| File | Purpose |
|------|---------|
| `certificates/local-cert.pem` | X.509 certificate (public) |
| `certificates/local-key.pem` | Private key |
| `certificates/local-cert.pfx` | PFX bundle for IdentityServer Kestrel |
| `certificates/localhost.pem` | **Combined cert+key for Traefik** (cert first, then key) |

Traefik uses `certificates/localhost.pem` via file certificates resolver (`certificatesresolvers.https.file.directory=/certs`).

## Development

### Running Locally (without Docker)
```bash
# IdentityServer
cd src/identityserver/identityserver
dotnet run

# Webapp
cd src/webapp
npm install
npm run dev
```

### Regenerating Traefik Combined Cert
```bash
cat certificates/local-cert.pem certificates/local-key.pem > certificates/localhost.pem
```

## Security Notes

- **Dev certificates** are self-signed — browsers will warn. Accept or add to trust store.
- **Traefik dashboard** at :8080 is unprotected — restrict in production.
- **Secrets** loaded from `.env.docker` — never commit this file.
- **Data protection keys** persisted in Docker volume `identityserver-keys`.

## CI/CD

GitHub Actions workflow (`.github/workflows/dockerhub.yml`):
- Triggers on push to `main`, tags `v*`, PRs to `main`
- Builds & pushes to Docker Hub using secrets:
  - `DOCKER_USER` — Docker Hub username
  - `DOCKER_TOKEN` — Docker Hub access token (needs **Read & Push** scope)

## Project Structure

```
.
├── .github/workflows/dockerhub.yml
├── docker-compose.yml
├── .env.docker.example
├── certificates/
│   ├── local-cert.pem
│   ├── local-key.pem
│   ├── local-cert.pfx
│   └── localhost.pem (Traefik combined)
├── scripts/
│   └── New-LocalDockerCertificate.ps1
├── src/
│   ├── identityserver/
│   │   └── identityserver/    # .NET 10 Duende IdentityServer
│   └── webapp/
│       ├── app/               # Next.js 16 App Router
│       │   ├── health/route.ts
│       │   ├── page.tsx
│       │   └── providers.tsx
│       ├── lib/auth.ts        # NextAuth config (JWT sessions)
│       ├── server.mjs         # HTTP server (TLS terminated by Traefik)
│       ├── Dockerfile
│       └── package.json
```

## License

MIT