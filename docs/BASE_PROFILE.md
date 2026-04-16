# Autonomous 314 — Base Runtime Profile

Last updated: **2026-04-16**

This page documents the **Base chain deployment profile** for Autonomous 314.

It is a **separate single-chain runtime** from the BNB Smart Chain deployment.
Use it when you deploy or integrate the Base instance of the protocol.

## Public network values

- **Chain:** Base
- **Chain ID:** `8453`
- **Native asset:** `ETH`
- **Wrapped native asset:** `WETH`
- **Canonical DEX:** QuickSwap V2
- **Recommended RPC:** `https://mainnet.base.org`
- **Explorer API:** `https://api.basescan.org/api`

## Base deployment parameters

- **Create fee (standard / taxed):** `0.005 ETH`
- **Create fee (whitelist / f314):** `0.01 ETH`
- **Graduation target:** `4 ETH`
- **Whitelist thresholds:** `1 / 2 / 3 ETH`
- **Whitelist seat sizes:** `0.04 / 0.1 / 0.2 / 0.5 ETH`
- **Whitelist max seats:** `80`

## Official Base deployment

- **Factory:** `0x95302fb1Aa9cD62F070E512B3d415d8388742a22`
- **Factory deployment tx:** `0x7f83969f3b8aecec11fc9b2adb98f55703b677e76678b8635973b4abdc7854ce`
- **Factory deployment block:** `44747121`
- **Deployment salt:** `0x910c5bb21b8b4100fd60a57155745d3aefb496aa859fc088f8136be56ca8ef31`

### Official Base support deployers

| Contract | Address | Deployment tx | Block |
|---|---|---|---|
| LaunchTokenDeployer | `0xEf6e2A4012012782520636f92411360Eef04e85F` | `0x42276e0768de38e285818c17755dda60dc6f89acd5e3aadf3ea5962633b7b7b7` | `44747109` |
| Whitelist LaunchCreate2Deployer | `0x7DC13A23cE2Ec1C0958a0edc9B2f48fB9B953Bf8` | `0x387c963aaf5b1a1b5f6c9e38e709dc1a13c393d8f6a3719431c160627fe4f4ad` | `44747112` |
| LaunchTokenTaxedDeployer | `0xD7d6cc1dD8ad78759b45243722dBb2be548a02b4` | `0x95d137375a88d8679226dfd00182006859bcdeac87ca3a2f5aae94e273450a4c` | `44747114` |
| WhitelistTaxed LaunchCreate2Deployer | `0x493F48a18C1c63D2B33bA0883FA85FF044bB70B6` | `0x2ae6c0300a23052b6e52a1f654106ba58fa02a86b5d4bea33576b91dce11d44b` | `44747117` |

### Create2 bind

- **Whitelist deployer bind tx:** `0xf147c80ae12331194aff5d082aa4079e21632986f9076c59ff0612bf02a8815d`
- **Whitelist deployer bind block:** `44747123`
- **Whitelist-taxed deployer bind tx:** `0x21aeed60812888771ba1379ed23d21458b86cde358b71174e563e005492ffb25`
- **Whitelist-taxed deployer bind block:** `44747125`

## vNext behavior

- **Tail handling:** when remaining quote capacity is at most `0.005 ETH` and the assist reserve covers it, the protocol closes the final edge so the DEX handoff completes cleanly.
- **Pre-grad transfer policy:** normal wallet-to-wallet transfers remain blocked until `DEXOnly`; transferring the launch token to its own contract address before graduation is treated as a sell into the internal market.

## Self-host notes

For a dedicated Base indexer deployment:

- `INDEXER_CHAIN_ID=8453`
- `INDEXER_RPC_URL=https://mainnet.base.org`
- `INDEXER_NATIVE_USD_PRICE_API_URL=https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd`
- `INDEXER_ETHERSCAN_API_URL=https://api.basescan.org/api`
- `INDEXER_BASESCAN_API_URL=https://api.basescan.org/api`
- `INDEXER_PUBLIC_BASE_URL=<base-indexer-public-origin>`
- `INDEXER_SOCIAL_NOTIFY_BASE_URL=<base-frontend-origin>`
- `INDEXER_METADATA_PUBLIC_ORIGINS=<base-frontend-origin>`
- `INDEXER_CORS_ORIGIN=<base-frontend-origin>`

The Base indexer should run as an **independent deployment**, not as a mixed-chain aggregator.

- `INDEXER_AUTO_VERIFY_BOOTSTRAP_OFFICIAL=1`
- `INDEXER_SOCIAL_NOTIFY_ENABLED=0`

## Frontend env keys

The current frontend only exposes the Base runtime when these values are configured:

- `VITE_BASE_RPC_URL`
- `VITE_BASE_FACTORY_ADDRESS`
- `VITE_BASE_INDEXER_API_URL`
- `VITE_BASE_INDEXER_SNAPSHOT_URL`

If `VITE_BASE_FACTORY_ADDRESS` is blank, the Base selector stays hidden so the public UI does not expose a half-configured chain.

## Notes

- Base uses the same launch families as the rest of the protocol:
  - `0314` — standard
  - `b314` — whitelist
  - `1314..9314` — taxed standard
  - `f314` — whitelist + tax
- The Base deployment keeps the same protocol semantics, but uses its own router, factory, deployers, and indexer.
- The Base public UI and Base indexer deployment can now use these addresses directly without changing the BNB Chain runtime.
