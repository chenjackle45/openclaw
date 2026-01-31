---
title: "Skills config(技能配置)"
summary: "技能配置的 Schema 定義與範例"
read_when:
  - 新增或修改技能配置時
  - 調整內置技能允許清單或安裝行為時
---

# 技能配置 (Skills Config)

所有與技能相關的配置都位於 `~/.openclaw/openclaw.json` 中的 `skills` 區塊下。

```json5
{
  skills: {
    allowBundled: ["gemini", "peekaboo"], // 僅限這幾項內置技能
    load: {
      extraDirs: ["~/Projects/my-skills"], // 額外載入目錄
      watch: true,                          // 啟用熱重載
      watchDebounceMs: 250
    },
    install: {
      preferBrew: true,                     // 優先使用 Homebrew 安裝
      nodeManager: "npm"                    // Node 套件管理器偏好
    },
    entries: {
      "nano-banana-pro": {
        enabled: true,
        apiKey: "GEMINI_KEY_HERE"
      }
    }
  }
}
```

## 欄位說明

- `allowBundled`：選用的**內置技能**允許清單。若設定此項，則只有清單內的內置技能會被載入（不影響管理型或工作區技能）。
- `load.extraDirs`：要掃描的額外技能目錄（優先順序最低）。
- `load.watch`：是否監視技能資料夾並在檔案變更時重新整理快照（預設：true）。
- `install.preferBrew`：當可用時，優先使用 Homebrew 安裝器（預設：true）。
- `install.nodeManager`：Node 安裝器偏好設定（`npm` | `pnpm` | `yarn` | `bun`）。這僅影響**技能安裝**；Gateway 本身仍應使用 Node 執行。
- `entries.<skillKey>`：針對個別技能的覆寫項。

個別技能欄位：
- `enabled`：設為 `false` 即可停用該技能（即使其已安裝）。
- `env`：為該次 Agent 執行注入的環境變數。
- `apiKey`：針對宣告了主環境變數的技能所提供的快速設定項。

## 注意事項

### 沙盒環境與環境變數
當會話處於**沙盒模式**時，技能進程會在 Docker 內部執行。沙盒**不會**繼承宿主機的 `process.env`。
請使用以下方式之一：
- `agents.defaults.sandbox.docker.env` 設定。
- 將環境變數直接封裝在您的自訂沙盒映射檔 (Image) 中。

全域 `env` 與 `skills.entries.<skill>.env` 僅適用於**宿主機直連 (Host)** 執行模式。
