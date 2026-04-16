# 2026-04-15 — Factory vNext public source release

This release publishes the new factory generation and related contract updates to the public repository.

## Included

- new BSC and Base official factory references
- `LaunchFactory` vNext deployment surface
- graduation hardening in `LaunchTokenBase`
- whitelist and taxed launch-family updates
- transfer-to-contract auto-sell support during bonding
- expanded factory and graduation regression tests

## Verification

- `pnpm --filter @autonomous314/contracts test test/LaunchFactory.test.ts test/LaunchToken.test.ts test/LaunchTokenTaxed.test.ts test/LaunchTokenWhitelist.test.ts test/LaunchTokenWhitelistTaxed.test.ts`
- `pnpm --filter @autonomous314/contracts test test/DeepAudit.test.ts`

## Public release boundary

- this release publishes the contract/source layer for open-source review and reuse
- it does not imply that every historical factory remains indexed on the official frontend
- old-factory homepage-card behavior is intentionally outside this public release scope
