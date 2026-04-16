# 2026-04-16 — 运行时与接入文档对齐

这次更新把公开技术文档同步到当前已部署的运行时行为。

## 对外行为说明更新

- BSC 官方 factory：`0xf264DEf5f915628c57190616931bDf19df2cf225`
- Base 官方 factory：`0x95302fb1Aa9cD62F070E512B3d415d8388742a22`
- 毕业前普通钱包到钱包 token 转账仍然禁止
- 毕业前把 launch token 转入 launch 合约地址，是卖出路径
- 毕业尾盘 assist 阈值是 `0.005 native`
- 旧工厂 launch 不进入官方首页发现列表，但直接 token 页面仍可按 token 地址读取详情和图表
- 公开 `GET /health` 继续保持最小响应；私有诊断需要带配置好的 bearer secret 访问 `GET /health/details`

## 验证

- `pnpm --filter @autonomous314/indexer test`
- `pnpm --filter @autonomous314/indexer build`
