---
title: "Plugin Bundles（外掛程式組合）"
summary: "安裝並使用 Codex、Claude 和 Cursor 組合作為 OpenClaw 外掛程式"
read_when:
  - 想要安裝 Codex、Claude 或 Cursor 相容組合時
  - 需要瞭解 OpenClaw 如何將組合內容對應至原生功能時
  - 除錯組合偵測或遺失功能時
---

# 外掛程式組合

OpenClaw 可以從三個外部生態系統安裝外掛程式：**Codex**、**Claude** 和 **Cursor**。這些被稱為**組合** — OpenClaw 對映至原生功能（如 skills、掛鉤和 MCP 工具）的內容和中繼資料包。

<Info>
  組合**不同於**原生 OpenClaw 外掛程式。原生外掛程式在流程內執行，可以註冊任何功能。組合是具有選擇性功能對映和較窄信任邊界的內容包。
</Info>

## 為什麼存在組合

許多有用的外掛程式以 Codex、Claude 或 Cursor 格式發佈。OpenClaw 不是要求作者將其改寫為原生 OpenClaw 外掛程式，而是偵測這些格式並將其支援的內容對映至原生功能集。這意味著您可以安裝 Claude 指令包或 Codex skill 組合並立即使用。

## 安裝組合

<Steps>
  <Step title="從目錄、封存或 marketplace 安裝">
    ```bash
    # 本地目錄
    openclaw plugins install ./my-bundle

    # 封存
    openclaw plugins install ./my-bundle.tgz

    # Claude marketplace
    openclaw plugins marketplace list <marketplace-name>
    openclaw plugins install <plugin-name>@<marketplace-name>
    ```

  </Step>

  <Step title="驗證偵測">
    ```bash
    openclaw plugins list
    openclaw plugins inspect <id>
    ```

    組合顯示為 `Format: bundle`，子類型為 `codex`、`claude` 或 `cursor`。

  </Step>

  <Step title="重啟並使用">
    ```bash
    openclaw gateway restart
    ```

    對映的功能（skills、掛鉤、MCP 工具）在下一個工作階段可用。

  </Step>
</Steps>

## OpenClaw 從組合對映的內容

目前並非每個組合功能都在 OpenClaw 中執行。以下是有效的內容和已偵測但尚未連接的內容。

### 現在支援

| 功能       | 如何對映                                                           | 適用於         |
| ---------- | ------------------------------------------------------------------ | -------------- |
| Skill 內容 | 組合 skill 根目錄載入為一般 OpenClaw skills                        | 所有格式       |
| 指令       | `commands/` 和 `.cursor/commands/` 被視為 skill 根目錄             | Claude、Cursor |
| 掛鉤包     | OpenClaw 風格 `HOOK.md` + `handler.ts` 佈局                        | Codex          |
| MCP 工具   | 組合 MCP 設定合併至內嵌 Pi 設定；支援的 stdio 伺服器作為子流程啟動 | 所有格式       |
| 設定       | Claude `settings.json` 匯入為內嵌 Pi 預設值                        | Claude         |

### 已偵測但未執行

這些已被識別並在診斷中顯示，但 OpenClaw 不執行它們：

- Claude `agents`、`hooks.json` 自動化、`lspServers`、`outputStyles`
- Cursor `.cursor/agents`、`.cursor/hooks.json`、`.cursor/rules`
- Codex 能力報告以外的內嵌/應用中繼資料

## 組合格式

<AccordionGroup>
  <Accordion title="Codex 組合">
    標記：`.codex-plugin/plugin.json`

    選用內容：`skills/`、`hooks/`、`.mcp.json`、`.app.json`

    Codex 組合當使用 skill 根目錄和 OpenClaw 風格的掛鉤包目錄（`HOOK.md` + `handler.ts`）時，最適合 OpenClaw。

  </Accordion>

  <Accordion title="Claude 組合">
    兩種偵測模式：

    - **基於清單：** `.claude-plugin/plugin.json`
    - **無清單：** 預設 Claude 佈局（`skills/`、`commands/`、`agents/`、`hooks/`、`.mcp.json`、`settings.json`）

    Claude 特定行為：

    - `commands/` 被視為 skill 內容
    - `settings.json` 匯入至內嵌 Pi 設定（shell 覆蓋金鑰被清理）
    - `.mcp.json` 將支援的 stdio 工具曝露至內嵌 Pi
    - `hooks/hooks.json` 已偵測但未執行
    - 清單中的自訂元件路徑是加法（它們延伸預設值，不替換預設值）

  </Accordion>

  <Accordion title="Cursor 組合">
    標記：`.cursor-plugin/plugin.json`

    選用內容：`skills/`、`.cursor/commands/`、`.cursor/agents/`、`.cursor/rules/`、`.cursor/hooks.json`、`.mcp.json`

    - `.cursor/commands/` 被視為 skill 內容
    - `.cursor/rules/`、`.cursor/agents/` 和 `.cursor/hooks.json` 僅限偵測

  </Accordion>
</AccordionGroup>

## 偵測優先順序

OpenClaw 首先檢查原生外掛程式格式：

1. `openclaw.plugin.json` 或具有 `openclaw.extensions` 的有效 `package.json` — 被視為**原生外掛程式**
2. 組合標記（`.codex-plugin/`、`.claude-plugin/` 或預設 Claude/Cursor 佈局）— 被視為**組合**

若目錄同時包含兩者，OpenClaw 使用原生路徑。這可防止雙格式套件被部分安裝為組合。

## 安全性

組合的信任邊界比原生外掛程式窄：

- OpenClaw **不** 在流程內載入任意組合執行時模組
- Skills 和掛鉤包路徑必須留在外掛程式根目錄內（邊界檢查）
- 設定檔案以相同邊界檢查讀取
- 支援的 stdio MCP 伺服器可能作為子流程啟動

這預設使組合更安全，但您仍應將第三方組合視為它們暴露的功能的受信內容。

## 疑難排解

<AccordionGroup>
  <Accordion title="組合已偵測但功能未執行">
    執行 `openclaw plugins inspect <id>`。若功能已列出但標示為未連接，這是產品限制 — 不是損壞的安裝。
  </Accordion>

  <Accordion title="Claude 指令檔案未出現">
    確保組合已啟用且 markdown 檔案在偵測到的 `commands/` 或 `skills/` 根目錄內。
  </Accordion>

  <Accordion title="Claude 設定未應用">
    僅支援來自 `settings.json` 的內嵌 Pi 設定。OpenClaw 不將組合設定視為原始設定修補。
  </Accordion>

  <Accordion title="Claude 掛鉤未執行">
    `hooks/hooks.json` 僅限偵測。若您需要可執行的掛鉤，使用 OpenClaw 掛鉤包佈局或發佈原生外掛程式。
  </Accordion>
</AccordionGroup>

## 相關主題

- [安裝和設定外掛程式](/zh-Hant/tools/plugin)
- [建構外掛程式](/zh-Hant/plugins/building-plugins) — 建立原生外掛程式
- [外掛程式清單](/zh-Hant/plugins/manifest) — 原生清單結構描述
