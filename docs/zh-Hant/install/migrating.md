---
title: "Migrating(遷移指南)"
summary: "將 OpenClaw 安裝從一台機器遷移（搬家）到另一台機器"
read_when:
  - 您正準備將 OpenClaw 搬移到新的筆電或伺服器時
  - 您希望保留會話紀錄、認證資訊以及頻道登入狀態 (WhatsApp 等) 時
---

# 遷移 OpenClaw 到新機器

本指南將引導您如何將 OpenClaw Gateway 遷移到新機器，且**不需重新執行入門引導流程**。

遷移的概念非常簡單：
- 複製 **狀態目錄** (`$OPENCLAW_STATE_DIR`，預設為 `~/.openclaw/`) —— 這包含配置、認證、會話紀錄與頻道狀態。
- 複製您的 **工作區**（預設為 `~/.openclaw/workspace/`）—— 這包含您的 Agent 檔案（記憶、提示詞等）。

但在處理**設定檔 (Profiles)**、**權限**以及**部分複製**時，有一些常見的陷阱需要注意。

## 開始之前（遷移內容清單）

### 1) 確定您的狀態目錄
大多數安裝使用預設值：`~/.openclaw/`。

如果您不確定，請在**舊**機器執行：
```bash
openclaw status
```
在輸出中查找 `OPENCLAW_STATE_DIR` 或設定檔名稱。如果您執行多個 Gateway，請針對每個設定檔重複此步驟。

### 2) 確定您的工作區
常見預設值：`~/.openclaw/workspace/`。
這是存放 `MEMORY.md`, `USER.md` 以及 `memory/*.md` 等檔案的地方。

### 3) 瞭解保留的內容
如果您複製了**狀態目錄**與**工作區**，您將保留：
- Gateway 配置 (`openclaw.json`)
- 認證設定檔 / API Key / OAuth 令牌
- 會話歷史與 Agent 狀態
- 頻道狀態（例如 WhatsApp 登入狀態）
- 您的工作區檔案（記憶、技能筆記等）

如果您**僅**複製工作區，則**不會**保留會話、憑證或頻道登入資訊。

## 遷移步驟 (推薦 path)

### 步驟 0 —— 製作備份（舊機器）
在舊機器上先停止 Gateway，確保檔案在複製過程中不會變動：
```bash
openclaw gateway stop
```

（建議做法）將狀態目錄與工作區打包：
```bash
cd ~
tar -czf openclaw-state.tgz .openclaw
tar -czf openclaw-workspace.tgz .openclaw/workspace
```

### 步驟 1 —— 在新機器安裝 OpenClaw
在**新**機器上安裝 CLI（視需要安裝 Node）：詳見 [安裝指南](/install)。
在此階段，如果入門引導建立了新的 `~/.openclaw/` 也是沒關係的，我們將在下個步驟覆蓋它。

### 步驟 2 —— 將狀態目錄與工作區複製到新機器
複製**兩者**：
- `$OPENCLAW_STATE_DIR` (預設為 `~/.openclaw/`)
- 您的工作區 (預設為 `~/.openclaw/workspace/`)

常用方法：`scp`、`rsync` 或行動硬碟。
複製後請確保：
- 隱藏目錄（如 `.openclaw/`）已被包含。
- 檔案擁有者權限對於執行 Gateway 的使用者是正確的。

### 步驟 3 —— 執行 Doctor（遷移與服務修復）
在**新**機器執行：
```bash
openclaw doctor
```
`doctor` 會修復服務、套用配置遷移，並針對不相符之處發出警告。

接著：
```bash
openclaw gateway restart
openclaw status
```

## 常見陷阱（以及如何避開）

- **陷阱：設定檔 / 狀態目錄不相符**：如果舊 Gateway 使用特定設定檔，新機器也必須使用相同的設定檔執行，否則會出現頻道消失或會話空白等症狀。
- **陷阱：僅複製 `openclaw.json`**：這是不夠的。許多供應商狀態存放在 `credentials/` 與 `agents/` 子目錄下。請務必遷移**整個**狀態目錄。
- **陷阱：權限與擁有者問題**：如果您是以 root 權限複製或更換了使用者，Gateway 可能會無法讀取憑證。請確保檔案擁有權正確。
- **陷阱：備份中的機密資訊**：狀態目錄包含 API Key 與 Token 等機密資訊。請務必加密存儲備份。

## 驗證檢查清單
在新機器上確認：
- `openclaw status` 顯示 Gateway 正在執行。
- 您的頻道仍處於連線狀態（例如 WhatsApp 不需要重新配對）。
- 儀表板能正常開啟並顯示現有的會話紀錄。
- 您的工作區檔案（記憶、配置）皆已到位。
