---
title: "遷移"
summary: "將 OpenClaw 安裝從一台機器遷移至另一台"
read_when:
  - 您正將 OpenClaw 移至新筆電/伺服器
  - 您想保留會話、認證與頻道登入（WhatsApp 等）
---

# 遷移 OpenClaw 至新機器

本指南在**無需重做引導**的情況下將 OpenClaw Gateway 從一台機器遷移至另一台。

遷移概念上很簡單：

- 複製**狀態目錄**（`$OPENCLAW_STATE_DIR`、預設：`~/.openclaw/`）— 包括配置、認證、會話與頻道狀態。
- 複製您的**工作區**（預設 `~/.openclaw/workspace/`）— 包括代理檔案（記憶體、提示等）。

但存在常見陷阱圍繞**設定檔**、**權限**與**部分複製**。

## 開始前（您要遷移什麼）

### 1) 識別狀態目錄

大多安裝使用預設：

- **狀態目錄：** `~/.openclaw/`

但若使用以下可能不同：

- `--profile <name>`（通常變成 `~/.openclaw-<profile>/`）
- `OPENCLAW_STATE_DIR=/some/path`

不確定時，在**舊**機器執行：

```bash
openclaw status
```

查找輸出中 `OPENCLAW_STATE_DIR` / 設定檔的提及。若執行多個 Gateway，每個設定檔重複。

### 2) 識別工作區

常見預設：

- `~/.openclaw/workspace/`（建議工作區）
- 您建立的自訂資料夾

您的工作區是 `MEMORY.md`、`USER.md` 和 `memory/*.md` 等檔案的位置。

### 3) 理解您將保留什麼

複製**兩者** —— 狀態目錄和工作區，您保留：

- Gateway 配置（`openclaw.json`）
- 認證設定檔 / API 金鑰 / OAuth 令牌
- 會話歷史 + 代理狀態
- 頻道狀態（例如 WhatsApp 登入/會話）
- 工作區檔案（記憶體、技能備註等）

複製**僅**工作區（例如透過 Git），您**不**保留：

- 會話
- 認證
- 頻道登入

這些位於 `$OPENCLAW_STATE_DIR`。

## 遷移步驟（建議）

### 步驟 0 — 備份（舊機器）

在**舊**機器上，先停止 Gateway 讓檔案在複製中間不變更：

```bash
openclaw gateway stop
```

（可選但建議）封存狀態目錄和工作區：

```bash
# 調整路徑若使用設定檔或自訂位置
cd ~
tar -czf openclaw-state.tgz .openclaw

tar -czf openclaw-workspace.tgz .openclaw/workspace
```

若有多個設定檔/狀態目錄（例如 `~/.openclaw-main`、`~/.openclaw-work`），封存每個。

### 步驟 1 — 在新機器安裝 OpenClaw

在**新**機器上，安裝 CLI（必要時安裝 Node）：

- 詳見：[安裝](/install)

此階段，引導建立新鮮 `~/.openclaw/` 可以 — 您將在下一步覆蓋。

### 步驟 2 — 複製狀態目錄 + 工作區至新機器

複製**兩者**：

- `$OPENCLAW_STATE_DIR`（預設 `~/.openclaw/`）
- 您的工作區（預設 `~/.openclaw/workspace/`）

常見方式：

- `scp` tarball 並解壓
- `rsync -a` 透過 SSH
- 外部磁碟

複製後，確保：

- 隱藏目錄被包括（例如 `.openclaw/`）
- 執行 Gateway 的使用者檔案所有權正確

### 步驟 3 — 執行 Doctor（遷移 + 服務修復）

在**新**機器上：

```bash
openclaw doctor
```

Doctor 是「安全無聊」的指令。修復服務、套用配置遷移與警告不匹配。

接著：

```bash
openclaw gateway restart
openclaw status
```

## 常見陷阱（與避免方式）

### 陷阱：設定檔 / 狀態目錄不匹配

若舊 Gateway 用設定檔（或 `OPENCLAW_STATE_DIR`）而新 Gateway 用不同的，您將見症狀如：

- 配置變更無效
- 頻道遺漏 / 登出
- 空會話歷史

修復：用遷移的**相同**設定檔/狀態目錄執行 Gateway/服務，再執行：

```bash
openclaw doctor
```

### 陷阱：僅複製 `openclaw.json`

`openclaw.json` 不足。許多供應商儲存狀態於：

- `$OPENCLAW_STATE_DIR/credentials/`
- `$OPENCLAW_STATE_DIR/agents/<agentId>/...`

始終遷移整個 `$OPENCLAW_STATE_DIR` 資料夾。

### 陷阱：權限 / 所有權

複製為 root 或變更使用者，Gateway 可能無法讀認證/會話。

修復：確保狀態目錄 + 工作區由執行 Gateway 的使用者擁有。

### 陷阱：遠端/本機模式間遷移

- UI（WebUI/TUI）指向**遠端** Gateway，遠端主機擁有會話儲存 + 工作區。
- 遷移筆電不會移遠端 Gateway 狀態。

遠端模式，遷移**Gateway 主機**。

### 陷阱：備份中的秘密

`$OPENCLAW_STATE_DIR` 含秘密（API 金鑰、OAuth 令牌、WhatsApp 認證）。如生產秘密對待備份：

- 存儲加密
- 避免透過不安全頻道共享
- 若懷疑暴露則輪轉金鑰

## 驗證檢清單

新機器上確認：

- `openclaw status` 顯示 Gateway 執行中
- 您的頻道仍連接（例如 WhatsApp 無需重新配對）
- 儀表板開啟並顯示現有會話
- 工作區檔案（記憶體、配置）存在

## 相關

- [Doctor](/gateway/doctor)
- [Gateway 故障排除](/gateway/troubleshooting)
- [OpenClaw 儲存資料在哪？](/help/faq#where-does-openclaw-store-its-data)
