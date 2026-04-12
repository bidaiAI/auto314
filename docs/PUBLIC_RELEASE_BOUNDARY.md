# Public Release Boundary Checklist

Last updated: **2026-04-11**

This checklist defines what belongs in the public MIT release mirror, what stays private, and what must be transformed before publication.

## 1) Publish as MIT

These are part of the open product and should be published to the public mirror:

- smart contracts,
- deployment scripts,
- frontend source,
- indexer source,
- tests,
- integration docs,
- self-hosting and release docs,
- reviewed release snapshots that still produce a runnable product.

## 2) Keep private

These should stay in the canonical development repo or in private infrastructure:

- secrets and live `.env` values,
- incident notes and internal runbooks,
- abuse heuristics, rate-limit thresholds, blocklists, and emergency procedures,
- unreleased branches, hotfix work, and debugging-only experiments,
- infrastructure access details that are not required for public integration.

## 3) Publish only after transformation

These may exist in the private repo, but they must be sanitized before entering the public mirror:

- deploy config files that point directly at official production services,
- example env files that contain official callback URLs or official writable service origins,
- docs that mix “official current instance” values with “copy this as your self-host default” guidance,
- branding and channel links used by forks without replacement.

## 4) Brand boundary

Code is open. Official identity is not automatically transferable.

Before a public fork or public mirror release:

- keep the official repo link only where it is intentional,
- point official channels only to the real official channels,
- require forks to replace official brand assets before public deployment,
- keep the brand policy in [`../TRADEMARKS.md`](../TRADEMARKS.md).

## 5) Release snapshot rule

The public mirror does **not** need to be a real-time mirror of private development.

It is acceptable for the public mirror to publish:

- a runnable snapshot from a previous day,
- a reviewed release branch,
- a backported stable reference backend / frontend pair.

But each public snapshot must satisfy all of these:

1. the frontend and backend are mutually compatible,
2. the product is runnable as released,
3. any known P0 security issues for the published surface are fixed or disabled,
4. the release notes state that the public repo is a reviewed snapshot, not the live private trunk.

## 6) Publication gate

Before pushing to the public mirror, confirm:

- [ ] public repo links are correct,
- [ ] public-stage copy was created from the intended snapshot,
- [ ] official production rewrites are removed from public deploy config,
- [ ] env examples use self-host placeholders,
- [ ] the released frontend/backend pair still runs,
- [ ] trademark notice is included,
- [ ] no secrets or live-only files entered the stage directory.
