# Autonomous 314 — Official Parameters

Last updated: **2026-04-15**

This page is the **canonical public reference** for the current official Autonomous 314 deployment and runtime profile.

If any summary elsewhere differs from this page, treat **this file** as the source of truth.

These are **official chain/runtime values**, not the default placeholders used by the public self-host templates.

## Official BSC runtime profile

- **Chain:** BNB Smart Chain
- **Chain ID:** `56`
- **Native asset:** `BNB`
- **Wrapped native asset:** `WBNB`
- **Canonical DEX:** PancakeSwap V2
- **Router:** `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- **Launch families:** `0314 / b314 / 1314..9314 / f314`
- **Create fee (standard / taxed):** `0.01 BNB`
- **Create fee (whitelist / f314):** `0.03 BNB`
- **Graduation target:** `12 BNB`
- **LP token reserve:** `20%`
- **Pre-grad fee split:** `1% total = 0.7% creator + 0.3% protocol`
- **Tail handling:** near graduation, the protocol automatically closes the remaining edge so the DEX handoff completes cleanly
- **Pre-grad transfer policy:** wallet-to-wallet transfers stay disabled until `DEXOnly`
- **Protocol treasury fallback:** `0xC4187bE6b362DF625696d4a9ec5E6FA461CC0314`

## Base runtime profile

This is the Base-specific runtime profile for a **separate single-chain deployment**.
It uses the same protocol families and integration surface, but with Base-native values.

- **Chain:** Base
- **Chain ID:** `8453`
- **Native asset:** `ETH`
- **Wrapped native asset:** `WETH`
- **Canonical DEX:** QuickSwap V2
- **Router:** `0x4a012af2b05616Fb390ED32452641C3F04633bb5`
- **Launch families:** `0314 / b314 / 1314..9314 / f314`
- **Create fee (standard / taxed):** `0.005 ETH`
- **Create fee (whitelist / f314):** `0.01 ETH`
- **Graduation target:** `4 ETH`
- **Whitelist thresholds:** `1 / 2 / 3 ETH`
- **Whitelist seat sizes:** `0.04 / 0.1 / 0.2 / 0.5 ETH`
- **Whitelist max seats:** `80`
- **Protocol treasury fallback:** `0xC4187bE6b362DF625696d4a9ec5E6FA461CC0314`

## Official Base factory

- **Factory:** `0x95302fb1Aa9cD62F070E512B3d415d8388742a22`
- **Factory deployment tx:** `0x7f83969f3b8aecec11fc9b2adb98f55703b677e76678b8635973b4abdc7854ce`
- **Factory deployment block:** `44747121`
- **Deployment salt:** `0x910c5bb21b8b4100fd60a57155745d3aefb496aa859fc088f8136be56ca8ef31`

## Official Base support deployers

| Contract | Address | Deployment tx | Block |
|---|---|---|---|
| LaunchTokenDeployer | `0xEf6e2A4012012782520636f92411360Eef04e85F` | `0x42276e0768de38e285818c17755dda60dc6f89acd5e3aadf3ea5962633b7b7b7` | `44747109` |
| Whitelist LaunchCreate2Deployer | `0x7DC13A23cE2Ec1C0958a0edc9B2f48fB9B953Bf8` | `0x387c963aaf5b1a1b5f6c9e38e709dc1a13c393d8f6a3719431c160627fe4f4ad` | `44747112` |
| LaunchTokenTaxedDeployer | `0xD7d6cc1dD8ad78759b45243722dBb2be548a02b4` | `0x95d137375a88d8679226dfd00182006859bcdeac87ca3a2f5aae94e273450a4c` | `44747114` |
| WhitelistTaxed LaunchCreate2Deployer | `0x493F48a18C1c63D2B33bA0883FA85FF044bB70B6` | `0x2ae6c0300a23052b6e52a1f654106ba58fa02a86b5d4bea33576b91dce11d44b` | `44747117` |

### Base Create2 bind

- **Whitelist deployer bind tx:** `0xf147c80ae12331194aff5d082aa4079e21632986f9076c59ff0612bf02a8815d`
- **Whitelist deployer bind block:** `44747123`
- **Whitelist-taxed deployer bind tx:** `0x21aeed60812888771ba1379ed23d21458b86cde358b71174e563e005492ffb25`
- **Whitelist-taxed deployer bind block:** `44747125`

## Official factory

- **Factory:** `0xf264DEf5f915628c57190616931bDf19df2cf225`
- **Factory deployment tx:** `0xbd39eadf6b753e05b1d4b8f9fb73d61eae9f72f3964026decbaec7aed825cb8a`
- **Factory deployment block:** `92738992`
- **Deployment salt:** `0xab555fe56c15787c95b52e9105e2183fbbfe1acdb806cec6fbc39bc7a3c953a0`

## Official support deployers

| Contract | Address | Deployment tx |
|---|---|---|
| LaunchTokenDeployer | `0x4A4b56885738A950F245F852143Dd75301B5c0dA` | `0x439bf06a068baceea7b6e7489bb3af176ee82b6fe78896c57391f8b622ffb861` |
| Whitelist LaunchCreate2Deployer | `0x4099ed5E06F4a8DfCFE05207f60ed520Cfa2e99c` | `0x92a6a5e3f0dfd619e03fe6c160ad84253ec2c90348b9f2192741a54161e7cf77` |
| LaunchTokenTaxedDeployer | `0x5CE6613F6640341d7440FD7c2Bb477BB0c91899E` | `0x2d63f031c300677e79a7c12c7a1e9494c0844af982d97166487e02ffcbf606c1` |
| WhitelistTaxed LaunchCreate2Deployer | `0x35758F11Eafa76B5cdFCf73d8495FB5D87446646` | `0xa3b954a5ce6e8da9ba89d8ba4dc54ce89732f7a279fa035f83c63adf95a761b5` |

### Create2 bind

- **Whitelist deployer bind tx:** `0xe162b6454dd5567e0c5b1021368a388099bb8c81ae0733c05405e5f2353658ea`
- **Whitelist deployer bind block:** `92738997`
- **Whitelist-taxed deployer bind tx:** `0x26e7f605dca41203a1bc94da7fdbf8ad5e2946f058b840355c4b37f134dde01a`
- **Whitelist-taxed deployer bind block:** `92739010`

## Curve profile

The official `12 BNB` profile uses:

- **virtualTokenReserve:** `107,036,752`
- **virtualQuoteReserve:** `4.60555128 BNB`

## Verification status

As of **2026-04-15**, the current official BSC and Base factories plus all four current support deployers on each chain are tracked here for source verification bootstrap and explorer matching.

- **Sourcify**
- **BscScan / Etherscan-compatible explorer**

Base deployment references are tracked separately in [`./BASE_PROFILE.md`](./BASE_PROFILE.md).

## Notes for integrators

- Use this page for the **current official deployment values**
- Use [`./INTEGRATION.md`](./INTEGRATION.md) for the **contract/API integration surface**
- Use [`./BASE_PROFILE.md`](./BASE_PROFILE.md) for the **Base chain deployment profile**
- Use [`./LAUNCH_METADATA.md`](./LAUNCH_METADATA.md) for the **metadata and social-link schema**
