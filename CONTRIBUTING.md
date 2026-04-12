# Contributing

Last updated: **2026-04-12**

Thanks for your interest in Autonomous 314.

## Repository model

This project uses:

- a canonical development repo for day-to-day work
- a public MIT release mirror at [bidaiAI/auto314](https://github.com/bidaiAI/auto314)

That means the public repo is **reviewed and manually published**, not a real-time mirror of every in-progress change.

## What should stay current in public

Even when the runnable app snapshot intentionally lags behind current private development, the public mirror aims to keep these surfaces current:

- `README.md`
- integration and metadata docs
- ABI artifacts
- public interface files
- release and security policy docs

## Good contribution targets

Useful public contributions include:

- documentation fixes
- integration clarifications
- UI / UX improvements
- bounded bug fixes
- tests for public behavior
- self-hosting improvements

## Before opening a PR

Please:

1. read [`README.md`](./README.md)
2. read [`SECURITY.md`](./SECURITY.md)
3. avoid publishing exploitable security details in public issues
4. keep changes focused and reviewable

## Development expectations

- use clear commit messages
- keep patches narrow
- prefer docs + tests when behavior changes
- do not add secrets, real `.env` files, or internal-only runbooks
- do not assume hidden source is part of the security model

## Public release boundary

Code is open under MIT, but official branding is not automatically granted for reuse.

See:

- [`TRADEMARKS.md`](./TRADEMARKS.md)
- [`docs/PUBLIC_RELEASE_BOUNDARY.md`](./docs/PUBLIC_RELEASE_BOUNDARY.md)

## Security issues

If your finding is security-sensitive, do **not** open a normal public bug report first.

Follow [`SECURITY.md`](./SECURITY.md).
