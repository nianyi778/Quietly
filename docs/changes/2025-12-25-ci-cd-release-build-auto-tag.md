# 变更记录

## 版本
- N/A（CI/CD 变更）

## 日期
- 2025-12-25

## 摘要
- 新增 GitHub Actions：在 push 到 `main` 时自动执行 `Release` 构建。
- 仅当远端不存在对应 tag 时，自动创建并推送 git tag：`v<MARKETING_VERSION>`。
- 将 `Quietly.app` 打包为 zip，并作为 workflow artifact 上传。

## 批准人
- likai（“批准实现” + “验收通过”）

## 备注
- CI 构建禁用代码签名（`CODE_SIGNING_ALLOWED=NO`、`CODE_SIGNING_REQUIRED=NO`），保证在无证书/无公证配置下可跑通流水线。
- 版本来源：从 Xcode build settings 读取 `MARKETING_VERSION`。
- 新增文件：`.github/workflows/release.yml`。
