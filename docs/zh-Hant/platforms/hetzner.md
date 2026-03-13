---
summary: "在便宜的 Hetzner VPS（Docker）上執行 OpenClaw Gateway 24/7，具有持久狀態和內置二進制檔案"
read_when:
  - 您想要 OpenClaw 在雲 VPS 上 24/7 執行（不在您的筆記本上）
  - 您想要自己 VPS 上的生產等級、始終開啟的 Gateway
  - 您想完全控制持久性、二進制檔案和重啟行為
  - 您在 Hetzner 或類似提供商上使用 Docker 執行 OpenClaw
title: "Hetzner"
---

# Hetzner 上的 OpenClaw（Docker、生產 VPS 指南）

## 目標

使用 Docker 在 Hetzner VPS 上執行持久的 OpenClaw Gateway，具有持久狀態、內置二進制檔案和安全重啟行為。

如果您想要「每月 ~$5 的 OpenClaw 24/7」，這是最簡單的可靠設定。
Hetzner 定價會變更；選擇最小的 Debian/Ubuntu VPS，如果遇到 OOM 則向上擴展。

安全模型提醒：

- 公司共享代理在所有人都在同一信任邊界且執行時僅用於業務時是可以的。
- 保持嚴格分離：專用 VPS/執行時 + 專用帳戶；該主機上沒有個人 Apple/Google/瀏覽器/密碼管理器配置。
- 如果使用者互相敵對，按 Gateway/主機/OS 使用者分割。

詳見 [安全](/zh-Hant/gateway/security) 和 [VPS 託管](/zh-Hant/vps)。

此指南已簡化為涵蓋主要步驟。詳細說明請參閱 [Docker 指南](/zh-Hant/install/docker)。
