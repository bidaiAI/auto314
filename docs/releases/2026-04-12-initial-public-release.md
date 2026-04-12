# Initial Public MIT Release — 2026-04-12

This is the **first public MIT release** of Autonomous 314.

## Release model

This repository is published as a **reviewed public snapshot**, not as a real-time mirror of day-to-day private development.

The goal is:

- open the protocol, contracts, frontend, and indexer under MIT
- keep production security based on runtime hardening rather than secrecy
- avoid publishing every in-progress debugging change immediately
- keep README and public integration/interface files current even when the runnable app snapshot intentionally lags

## Snapshot basis

The released product surface is based on the reviewed runnable snapshot:

- source snapshot commit: `ae67b87e59370c1ea128a08a39693c99ee18d002`
- source snapshot time: **2026-04-06 07:23:25 -0500**

## Included in this release

- factory and launch contracts
- reference frontend
- reference indexer
- deployment scripts
- integration and metadata docs
- public release policy and boundary docs
- latest public-facing README, ABI artifacts, and interface/spec files

## Intentionally not included

This first public release intentionally does **not** include all recent internal work.

Examples of excluded material:

- newer unpublished debugging work from the last few development days
- private operational runbooks
- live secrets and real environment files
- internal abuse heuristics and emergency response details

## Public-release hardening applied

For this first public release:

- public repo links were normalized to the new public repository
- public env examples were sanitized for self-hosting
- reference metadata upload is **disabled by default**
- `/health` was reduced to a minimal readiness response
- trademark / brand boundaries were documented
- a public security policy was added

## Verification performed before release

The reviewed public-stage copy was verified locally with:

- `pnpm install --frozen-lockfile --offline`
- `pnpm --filter @autonomous314/indexer build`
- `pnpm --filter @autonomous314/web build`
- `pnpm test`

## Notes for self-hosters

If you enable write surfaces such as metadata upload in your own deployment, add your own:

- authentication
- abuse controls
- storage cleanup policy
- rate limits

The public release defaults are intentionally conservative.
