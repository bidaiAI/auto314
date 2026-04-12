# Public Release Sanitization Map

Last updated: **2026-04-11**

This document lists the files that currently need sanitization or explicit handling before publication to the public mirror.

## Files transformed for public release

| Path | Why it needs handling | Public release action |
|---|---|---|
| `apps/web/.env.example` | Previously pointed at official indexer URLs | Sanitized in-place to self-host placeholders |
| `apps/indexer/.env.example` | Previously pointed at official frontend origin and official callback URLs | Sanitized in-place to self-host placeholders |
| `vercel.json` | The canonical deployment config may point rewrites at official production indexers | Keep the canonical file out of the public release as-is; public-stage flow overwrites it with `release/public-stage-overrides/vercel.json` |
| `docs/OFFICIAL_PARAMETERS.md` | Contains official live public endpoints | Keep public, but clarify that it is an official-instance reference, not a self-host default template |
| `docs/BASE_PROFILE.md` | Contains official Base public endpoints | Keep public, but clarify that it is an official-instance reference, not a self-host default template |

## Files intentionally left public

These are public by design and are not treated as secrets:

- onchain factory addresses,
- deployment transactions and blocks,
- official frontend URL,
- official public social channels,
- protocol docs and integration docs.

## Files intentionally left private

These should never enter the public mirror from the canonical development repo:

- real `.env` files,
- `.vercel/`,
- `.playwright-cli/`,
- `output/`,
- local debug artifacts,
- internal-only notes and unpublished assets.

## Release tooling

The public-stage flow uses:

- snapshot manifest: `release/public-stage.manifest`
- overlay manifest: `release/public-stage-overlay.manifest`
- overrides: `release/public-stage-overrides/`
- version-specific overrides: `release/public-stage-version-overrides/`
- builder script: `scripts/prepare-public-stage.sh`

The builder can stage from an older source snapshot by passing that snapshot path as the second argument. In that mode, runnable code comes from the older snapshot while current public-release docs and sanitization files are layered on top from the canonical development repo. If one specific snapshot needs a narrow backport or extra hardening before publication, place that patch under `release/public-stage-version-overrides/<git-short-sha>/`.
