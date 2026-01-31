---
title: "sandbox(沙盒管理)"
summary: "管理沙盒容器並盤查有效的沙盒政策"
read_when: "正在管理沙盒容器或調試沙盒/工具原則行為時。"
---

# 沙盒管理 CLI (Sandbox CLI)

管理基於 Docker 的沙盒容器，用於隔離 Agent 的執行環境。

## 總覽

為了安全性，OpenClaw 可以將 Agent 運行在隔離的 Docker 容器中。`sandbox` 指令能協助您管理這些容器，尤其是在系統更新或配置變更之後。

## 指令說明

### `openclaw sandbox explain`

盤查目前的**有效**沙盒模式、範圍、工作區存取權限、沙盒工具原則以及提權守門員（包含對應的配置修復路徑）。

```bash
# 解釋目前的沙盒設定
openclaw sandbox explain

# 解釋特定會話的沙盒設定
openclaw sandbox explain --session agent:main:main

# 以 JSON 格式輸出
openclaw sandbox explain --json
```

### `openclaw sandbox list`

列出所有的沙盒容器及其狀態與配置。

```bash
# 列出所有沙盒
openclaw sandbox list

# 僅列出瀏覽器容器
openclaw sandbox list --browser

# JSON 格式輸出
openclaw sandbox list --json
```

**輸出內容包含：**
- 容器名稱與狀態（運行中/已停止）
- Docker 映像檔（以及是否與配置匹配）
- 建立時間（Age）
- 閒置時間（Idle time）
- 關聯的會話/Agent

### `openclaw sandbox recreate`

移除沙盒容器，以強制使用更新後的映像檔或配置重新建立。

```bash
# 重新建立所有容器
openclaw sandbox recreate --all

# 針對特定會話重新建立
openclaw sandbox recreate --session main

# 針對特定 Agent 重新建立
openclaw sandbox recreate --agent mybot

# 強制重新建立且不顯示確認提示
openclaw sandbox recreate --all --force
```

**重要提示**：當 Agent 下次被調用時，系統會自動重新建立容器。

## 常見情境

### 在更新 Docker 映像檔後

```bash
# 拉取新映像檔
docker pull openclaw-sandbox:latest
docker tag openclaw-sandbox:latest openclaw-sandbox:bookworm-slim

# 更新配置以使用新映像檔後，重新建立容器
openclaw sandbox recreate --all
```

### 在變更沙盒配置或 setupCommand 後

```bash
# 編輯配置後重新建立以套用新設定
openclaw sandbox recreate --all
```

## 為什麼需要這個指令？

**問題**：當您更新沙盒 Docker 映像檔或變更配置時：
- 既有的容器會繼續使用舊設定運行。
- 容器僅在閒置 24 小時後才會被自動清理。
- 頻繁使用的 Agent 可能會導致舊容器無限期運行。

**解決方案**：使用 `openclaw sandbox recreate` 強制移除舊容器。當下次需要時，它們會依據目前的設定自動重新建立。

提示：建議優先使用 `openclaw sandbox recreate` 而非手動執行 `docker rm`，因為它能確保與 Gateway 的命名規則及會話金鑰匹配。

## 配置說明

沙盒設定位於 `~/.openclaw/openclaw.json` 的 `agents.defaults.sandbox` 下：

```jsonc
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "all",                    // off, non-main, all
        "scope": "agent",                 // session, agent, shared
        "docker": {
          "image": "openclaw-sandbox:bookworm-slim",
          "containerPrefix": "openclaw-sbx-"
        },
        "prune": {
          "idleHours": 24,               // 閒置 24 小時後自動清理
          "maxAgeDays": 7                // 最長存留 7 天
        }
      }
    }
  }
}
```

## 相關連結

- [沙盒技術文件](/gateway/sandboxing)
- [Agent 配置導覽](/concepts/agent-workspace)
- [Doctor 指令](/gateway/doctor) —— 盤查沙盒安裝狀態
