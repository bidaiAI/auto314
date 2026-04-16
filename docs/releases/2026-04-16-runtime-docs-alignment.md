# 2026-04-16 — Runtime and integration docs alignment

This update aligns the public technical docs with the currently deployed runtime behavior.

## Updated public behavior notes

- BSC official factory: `0xf264DEf5f915628c57190616931bDf19df2cf225`
- Base official factory: `0x95302fb1Aa9cD62F070E512B3d415d8388742a22`
- pre-graduation wallet-to-wallet token transfers remain disabled
- pre-graduation transfer of the launch token to the launch contract address is a sell path
- the graduation tail assist threshold is `0.005 native`
- old factory launches stay out of official homepage discovery, but direct token pages may still hydrate token-scoped details and charts
- public `GET /health` remains minimal; private diagnostics require `GET /health/details` with the configured bearer secret

## Verification

- `pnpm --filter @autonomous314/indexer test`
- `pnpm --filter @autonomous314/indexer build`
