---
summary: "Skills 設定結構及範例"
read_when:
  - 新增或修改 Skills 設定時
  - 調整綑綁允許清單或安裝行為時
title: "Skills Config（Skills 設定）"
---

# Skills Config

所有 Skills 相關設定位於 `~/.openclaw/openclaw.json` 中的 `skills`。

```json5
{
  skills: {
    allowBundled: ["gemini", "peekaboo"],
    load: {
      extraDirs: ["~/Projects/agent-scripts/skills", "~/Projects/oss/some-skill-pack/skills"],
      watch: true,
      watchDebounceMs: 250,
    },
    install: {
      preferBrew: true,
      nodeManager: "npm", // npm | pnpm | yarn | bun (Gateway runtime still Node; bun not recommended)
    },
    entries: {
      "nano-banana-pro": {
        enabled: true,
        apiKey: { source: "env", provider: "default", id: "GEMINI_API_KEY" }, // 或純文字字串
        env: {
          GEMINI_API_KEY: "GEMINI_KEY_HERE",
        },
      },
      peekaboo: { enabled: true },
      sag: { enabled: false },
    },
  },
}
```

## 欄位

- `allowBundled`：**僅限綑綁** Skills 的選用允許清單。設定時，僅清單中的綑綁 Skills 符合資格（不影響受管／Workspace Skills）。
- `load.extraDirs`：要掃描的額外 Skill 目錄（優先級最低）。
- `load.watch`：監視 Skill 資料夾並重新整理 Skills 快照（預設：true）。
- `load.watchDebounceMs`：Skill 監視器事件的去抖動毫秒數（預設：250）。
- `install.preferBrew`：可用時偏好 brew 安裝程式（預設：true）。
- `install.nodeManager`：Node 安裝程式偏好（`npm` | `pnpm` | `yarn` | `bun`，預設：npm）。這僅影響 **Skill 安裝**；Gateway runtime 應該仍為 Node（不建議用於 WhatsApp／Telegram 的 Bun）。
- `entries.<skillKey>`：每個 Skill 的覆寫。

每個 Skill 的欄位：

- `enabled`：設定為 `false` 以停用 Skill，即使它已綑綁／安裝。
- `env`：為 Agent 執行注入的環境變數（僅當未設定時）。
- `apiKey`：為宣告主要環境變數的 Skills 提供的選用便利。支援純文字字串或 SecretRef 物件（`{ source, provider, id }`）。

## 注意事項

- `entries` 下的鍵預設對應到 Skill 名稱。若 Skill 定義了 `metadata.openclaw.skillKey`，改用該鍵。
- 當監視器啟用時，下一個 Agent 回合會選取對 Skills 的變更。

### 沙箱 Skills + 環境變數

當工作階段被**沙箱化**時，Skill 進程在 Docker 內執行。沙箱**不會**繼承主機 `process.env`。

使用以下之一：

- `agents.defaults.sandbox.docker.env`（或每個 Agent `agents.list[].sandbox.docker.env`）
- 將環境烘焙到自訂沙箱映像中

全域 `env` 和 `skills.entries.<skill>.env/apiKey` 僅適用於**主機**執行。
