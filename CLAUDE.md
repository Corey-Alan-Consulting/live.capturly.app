# live.capturly.app

Capturly Live: Capturly's self-hosted, branded deployment of VDO.Ninja (browser
peer-to-peer live audio/video for remote guests), served as a static site from
`Dockerfile` + `nginx.conf` at https://live.capturly.app. A fork under AGPL-3.0;
the complete corresponding source of the deployed instance is this repository.

<!-- SYNCED FROM framework/agents/base.md @ c966170 — do not edit here; fix in framework and re-sync. -->


# Corey Alan Consulting — org rules

This repo belongs to Corey Alan Consulting and runs on the company platform (GKE prod + K3s staging, GitOps via ArgoCD). The authoritative engineering standards live in the `framework` repo (`Corey-Alan-Consulting/framework`, locally usually `../framework`); where this file and framework disagree, framework wins. Its `llms.txt` indexes every page.

## Stack (org default)

TypeScript (strict) · Next.js App Router · pnpm 10 + Turborepo · Prisma + PostgreSQL · Redis via ioredis (Sentinel, fail-open) · NextAuth v5 through `@corey-alan-consulting/auth-core` · Tailwind + Radix · Vitest + Playwright · Changesets for releases · Sentry. Check this repo's `package.json` before assuming versions — repos migrate at different speeds.

## Non-negotiables

1. **No secrets in code, config, or output.** Secrets come from Bitwarden Secrets Manager via `.envrc` (local) or the platform pipeline (deployed). Never commit a value, never print one, never invent an `.env` workaround. `framework/standards/security/secrets.md`.
2. **Conventional Commits** for all commit messages and PR titles (`feat(scope): …`, `fix: …`); CI enforces PR titles. User-visible changes need a Changeset.
3. **Never weaken CI gates**: Trivy severity gates, CodeQL upload, action SHA-pinning, zizmor findings, `id-token` permissions. If a gate blocks you, fix the finding.
4. **Deployment is GitOps.** No `kubectl` against clusters, no manual image tags, no editing `platform-infra` rendered YAML by hand. Images are digest-pinned and Cosign-signed by the shared workflows. `framework/platform/app-contract.md`.
5. **Don't hand-roll what the platform provides**: auth (`auth-core`), rate limiting (shared presets), Redis client (Sentinel fail-open singleton), Dockerfiles (`.prebuilt`/`.migrate` pattern), CI (callers of `deploy-workflows`).
6. **Database changes go through Prisma migrations** and ship in the separate migration image; never mutate schema at app startup.
7. **Errors are handled loudly**: report to Sentry, no silently swallowed catches, rate limiters and caches fail open by design — but say so in code.

## When unsure

Consult framework first: `standards/` for requirements, `platform/` for infra contracts, `guides/` for procedures, `decisions/` for why. If framework lacks the answer, say so rather than inventing a convention, and flag it for `framework/meta/BACKLOG.md`.

<!-- END SYNC: framework/agents/base.md -->

## Rules of this repo

- The engine is upstream's: only branding, deployment configuration and the
  files README.md lists under "What differs from upstream" change here. Fixes to
  the engine go upstream.
- Keep attribution and the footer "Source Code" link (AGPL compliance).
- No package.json at the root: there is no lint, type-check or test gate; the
  signaling server lives in `capturly-live-signaling`.
