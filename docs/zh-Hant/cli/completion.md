---
summary: "CLI 參考用於 `openclaw completion`（產生/安裝 shell 完成指令碼）"
read_when:
  - 您想要 zsh/bash/fish/PowerShell 的 shell 完成
  - 您需要在 OpenClaw 狀態下快取完成指令碼
title: "completion（Shell 補全）"
---

# `openclaw completion`

產生 shell 完成指令碼並選擇性地將其安裝到您的 shell 設定檔。

## 使用方式

```bash
openclaw completion
openclaw completion --shell zsh
openclaw completion --install
openclaw completion --shell fish --install
openclaw completion --write-state
openclaw completion --shell bash --write-state
```

## 選項

- `-s, --shell <shell>`：shell 目標（`zsh`、`bash`、`powershell`、`fish`；預設：`zsh`）
- `-i, --install`：透過將來源行新增到您的 shell 設定檔來安裝完成
- `--write-state`：將完成指令碼寫入 `$OPENCLAW_STATE_DIR/completions` 而不列印到 stdout
- `-y, --yes`：跳過安裝確認提示

## 註

- `--install` 將小「OpenClaw 完成」區塊寫入您的 shell 設定檔並指向快取的指令碼。
- 沒有 `--install` 或 `--write-state`，命令將指令碼列印到 stdout。
- 完成產生急切地載入命令樹，所以包含嵌套子命令。
