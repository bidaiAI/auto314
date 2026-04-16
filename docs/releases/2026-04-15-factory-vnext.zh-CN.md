# 2026-04-15 — Factory vNext 公开源码发布

这次发布把新一代工厂合约及相关合约更新同步到了公开仓库。

## 本次包含

- 新的 BSC / Base 官方 factory 参考地址
- `LaunchFactory` vNext 部署面
- `LaunchTokenBase` 的毕业链路加固
- 白名单与税收家族更新
- bonding 阶段“转入合约地址即卖出”支持
- 更完整的工厂与毕业回归测试

## 验证

- `pnpm --filter @autonomous314/contracts test test/LaunchFactory.test.ts test/LaunchToken.test.ts test/LaunchTokenTaxed.test.ts test/LaunchTokenWhitelist.test.ts test/LaunchTokenWhitelistTaxed.test.ts`
- `pnpm --filter @autonomous314/contracts test test/DeepAudit.test.ts`

## 公开发布边界

- 这次发布的是可供审阅与复用的合约/源码层
- 不代表所有历史工厂都会继续出现在官方前端索引里
- 旧工厂首页卡片行为不在本次公开发布范围内
