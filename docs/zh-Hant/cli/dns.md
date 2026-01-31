---
title: "dns(DNS 配置)"
summary: "`openclaw dns` CLI 參考（廣域發現協助工具）"
read_when:
  - 想要透過 Tailscale + CoreDNS 實現廣域發現 (Wide-Area DNS-SD) 時
  - 正在為自定義發現網域（如 openclaw.internal）設定 Split DNS 時
---

# `openclaw dns`

用於廣域發現 (Wide-area discovery) 的 DNS 協助工具（基於 Tailscale 與 CoreDNS）。目前主要優化於 macOS 環境搭配 Homebrew 管理的 CoreDNS。

相關資訊：
- Gateway 發現機制：[發現機制 (Discovery)](/gateway/discovery)
- 廣域發現配置：[配置導覽 (Configuration)](/gateway/configuration)

## 設定指令

```bash
# 查看目前的 DNS 設定建議
openclaw dns setup

# 執行並套用 DNS 配置
openclaw dns setup --apply
```
