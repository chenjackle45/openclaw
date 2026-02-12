---
summary: "節點配對、連接和命令疑難排解"
read_when:
  - 節點無法連接到 Gateway
  - 裝置配對失敗
  - 節點命令失敗或逾時
title: "Node Troubleshooting（節點疑難排解）"
---

# 節點疑難排解

## 節點無法連接

**症狀：** `openclaw node run` 啟動但立即退出或掛起。

**檢查：**

1. Gateway 執行中且可達：`openclaw status` 在 Gateway 主機上
2. 防火牆允許 WebSocket 連接到 Gateway 連接埠（預設 18789）
3. 節點和 Gateway 在相同網路上，或透過 SSH 隧道連接
4. Gateway 有效的標記被傳遞（`OPENCLAW_GATEWAY_TOKEN`）

## 裝置配對待審

**症狀：** `openclaw nodes status` 顯示節點為「待審配對」。

**修正：**

```bash
openclaw devices list          # 列出待審請求
openclaw devices approve <id>  # 核准特定請求
```

## 節點命令逾時

**症狀：** `canvas.screenshot` 或其他節點命令返回逾時。

**檢查：**

- 節點程序執行中：`openclaw nodes status`
- 連接埠監聽中：`ss -ltnp | grep 18789`
- 重新啟動節點程序

## 遠端執行（system.run）失敗

**症狀：** 選擇 `host=node` 的命令失敗或顯示「拒絕」。

**檢查：**

- 節點主機執行中：`openclaw node run ...` 在遠端機器上
- 核准白名單包含命令：`~/.openclaw/exec-approvals.json`
- 網路連接：Gateway 可以到達節點

詳見 [Nodes](/zh-Hant/nodes) 完整設定指南。
