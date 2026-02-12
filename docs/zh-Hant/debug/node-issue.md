---
summary: "調試節點連接和命令問題"
read_when:
  - 節點無法連接
  - 節點命令失敗
  - 列印節點日誌
title: "Node + tsx Crash（節點問題調試）"
---

# 調試節點問題

## 檢查節點狀態

```bash
openclaw nodes status
openclaw nodes describe --node <id>
```

## 查看日誌

```bash
openclaw logs tail --filter "node"
```

## 重新啟動節點

```bash
openclaw node restart
```

## 檢查連接

驗證 Gateway WebSocket 可達：

```bash
openclaw status
```

詳見 [Nodes](/zh-Hant/nodes) 和 [Troubleshooting](/zh-Hant/nodes/troubleshooting)。
