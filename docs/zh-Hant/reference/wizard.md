---
summary: "OpenClaw 上線精靈流程和設定步驟"
read_when:
  - 執行 openclaw onboard
  - 自訂精靈行為或流程
  - 調試上線問題
title: "Onboarding Wizard Reference（上線精靈）"
---

# 上線精靈

OpenClaw 包括一個互動式 `onboard` 命令，用於初始設定。

## 啟動精靈

```bash
openclaw onboard
```

## 精靈步驟

1. **歡迎** - 簡介和先決條件檢查
2. **API 金鑰** - 設定 Anthropic 或其他提供者金鑰
3. **頻道登入** - 配對 WhatsApp、Telegram 或其他訊息應用
4. **Gateway 啟動** - 啟動 Gateway 程序
5. **確認** - 測試和確認設定

## 安裝守護程式

精靈可以選擇性安裝後台服務：

```bash
openclaw onboard --install-daemon
```

## 跳過步驟

要跳過特定步驟：

```bash
openclaw onboard --skip-channels --skip-daemon
```

詳見 `openclaw onboard --help` 以查看所有選項。
