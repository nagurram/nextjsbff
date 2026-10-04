This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [https://localhost:3000](https://localhost:3000) with your browser to see the result.

## IdentityServer OIDC

The app uses the NextAuth.js IdentityServer4 provider with the local IdentityServer configured in `src/identityserver/identityserver/Config.cs`. The interactive client uses authorization code flow and requests `openid profile scope2`.

Create `src/webapp/.env.local` from `.env.example`. Set `IDENTITY_SERVER_CLIENT_SECRET` to the raw secret configured for the `interactive` client in `Config.cs`, and set `NEXTAUTH_SECRET` to a newly generated random secret (for example, `openssl rand -base64 32`). The issuer and client ID defaults match the local IdentityServer configuration and can be overridden through environment variables.

Run IdentityServer at `https://localhost:5001` and the web app at `https://localhost:3000`. On Windows, `npm run dev` verifies that IdentityServer presents the trusted .NET development certificate and exports only its public certificate to the ignored `certificates` directory. NextAuth uses that certificate specifically for IdentityServer HTTPS requests; normal TLS verification remains enabled. The dev script also starts Node with `--use-system-ca`, which requires Node 24.6+ or 22.15+. The IdentityServer client's redirect URI must be `https://localhost:3000/api/auth/callback/identity-server4`.

## Run both apps with Docker Compose

On Windows, first generate and trust a local certificate whose SANs cover both `localhost` and `identityserver.localhost`:

```powershell
.\scripts\New-LocalDockerCertificate.ps1
Copy-Item .env.docker.example .env.docker
# Edit .env.docker and replace both placeholder values.
docker compose --env-file .env.docker up --build
```

The script stores the certificate, private key, and IdentityServer PFX under the git-ignored repository-root `certificates` directory, and trusts the certificate for the current Windows user. Compose mounts these files read-only into both containers: Next.js serves HTTPS with the PEM keypair and trusts the certificate for OIDC discovery, while Kestrel serves HTTPS with the PFX. Open `https://localhost:3000`; the browser uses `https://identityserver.localhost:5001` for the OIDC authority, and the Compose network routes that hostname to the IdentityServer container. The certificate private key is local development material only; do not use it in production.

Compose persists IdentityServer signing keys and diagnostics in named volumes. To stop the stack, run `docker compose --env-file .env.docker down`; add `-v` only if you also want to remove the persisted IdentityServer data.

## Publish Docker images

The GitHub Actions workflow builds both images on pull requests to `main` and publishes them to Docker Hub on pushes to `main`, version tags (`v*`), and manual workflow runs. Add repository actions secrets named `DOCKER_USER` (Docker Hub username) and `DOCKER_TOKEN` (Docker Hub access token). The images are published as `<DOCKER_USER>/nextjsbff-webapp` and `<DOCKER_USER>/nextjsbff-identityserver`, with branch/tag, commit SHA, and (on the default branch) `latest` tags.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
