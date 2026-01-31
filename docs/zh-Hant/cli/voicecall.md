---
title: "voicecall(語音通話外掛)"
summary: "`openclaw voicecall` CLI 參考（語音通話外掛指令介面）"
read_when:
  - 使用語音通話外掛並需要 CLI 入口點資訊時
  - 需要 `voicecall call|continue|status|tail|expose` 等指令的快速範例時
---

# `openclaw voicecall`

`voicecall` 是由外掛提供的指令。僅在安裝並啟用語音通話 (voice-call) 外掛後才會顯示。

相關資訊：
- 語音通話外掛主頁：[語音通話 (Voice Call)](/plugins/voice-call)

## 常見指令

```bash
# 查看特定通話 ID 的狀態
openclaw voicecall status --call-id <ID>

# 發起語音通話（通知模式）
openclaw voicecall call --to "+15555550123" --message "你好" --mode notify

# 接續現有的通話並發送訊息
openclaw voicecall continue --call-id <ID> --message "有任何問題嗎？"

# 結束通話
openclaw voicecall end --call-id <ID>
```

## 暴露 Webhooks (透過 Tailscale)

```bash
# 以 Serve 模式暴露
openclaw voicecall expose --mode serve

# 以 Funnel 模式暴露
openclaw voicecall expose --mode funnel

# 取消暴露
openclaw voicecall unexpose
```

**安全性提示**：請僅將 Webhook 端點暴露給您信任的網路。在可能的情況下，優先選用 `Tailscale Serve` 而非 `Funnel`。
