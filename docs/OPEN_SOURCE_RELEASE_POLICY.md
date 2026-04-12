# Autonomous 314 Open-Source Release Policy

Last updated: **2026-04-11**

This project uses a **canonical development repo** and a **public MIT release mirror**:

- **Public repository:** [https://github.com/bidaiAI/auto314](https://github.com/bidaiAI/auto314)
- **License:** [MIT](../LICENSE)
- **Release model:** reviewed, manual publication to the public repo

## Why this model exists

The protocol now assumes that meaningful security must survive public source availability.

The goal is **not** to hide production risk behind private code. The goal is to:

1. keep day-to-day development and hotfix work in the canonical development repo,
2. publish reviewed source to the public MIT repo on purpose,
3. treat runtime hardening as the real security boundary.

## What is public

The public MIT repo is the release-facing source of truth for:

- contracts,
- frontend,
- indexer,
- protocol docs,
- integration docs,
- reviewed release snapshots.

## What remains private

These do **not** rely on source secrecy, but they are still operationally private:

- secrets and live environment values,
- internal runbooks,
- incident notes,
- abuse heuristics and enforcement thresholds,
- unreleased branches and hotfixes before review,
- infrastructure access details that are not needed for public integration.

## Core invariants

Every public release should satisfy these rules:

1. **Assume attackers can read the code.**
2. **Do not expose anonymous write paths to production services.**
3. **Do not ship public configs that point directly at sensitive production internals unless intended.**
4. **Do not publish secrets, internal-only env values, or emergency procedures.**
5. **Do not depend on “security through obscurity” for API safety.**

## Minimum security bar before a public release

- authenticated write endpoints for upload / trigger flows,
- rate limits and abuse controls on public POST surfaces,
- upload TTL / cleanup / quota handling,
- minimized health endpoints,
- SSRF-safe metadata fetch behavior,
- sanitized public docs and public config defaults,
- passing tests for the touched surfaces.

## Recommended local remote layout

Keep the canonical development repo as `origin`, and add the public mirror as a second remote:

```bash
git remote add public git@github.com:bidaiAI/auto314.git
```

## Manual release flow

Typical publication flow:

1. develop and review in the canonical development repo,
2. complete security fixes and sanitization,
3. verify docs / frontend links / public defaults,
4. push the reviewed state manually to the public repo,
5. publish only the versions you want the public mirror to carry.

The public repo is intentionally **not** a real-time mirror of day-to-day development.

## Supporting documents

- Public release boundary: [`docs/PUBLIC_RELEASE_BOUNDARY.md`](./PUBLIC_RELEASE_BOUNDARY.md)
- Public-stage release flow: [`docs/PUBLIC_STAGE_RELEASE.md`](./PUBLIC_STAGE_RELEASE.md)
- Sanitization map: [`docs/PUBLIC_SANITIZATION_MAP.md`](./PUBLIC_SANITIZATION_MAP.md)
- Trademark and brand policy: [`../TRADEMARKS.md`](../TRADEMARKS.md)
