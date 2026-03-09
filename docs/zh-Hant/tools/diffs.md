---
title: "Diffs（差異比較）"
summary: "代理的唯讀 diff 檢視器和檔案渲染器（選用 plugin 工具）"
description: "使用選用的 Diffs plugin 將前後文字或統一 patch 渲染為 gateway 託管的 diff 檢視，或渲染為檔案（PNG 或 PDF），或兩者兼具。"
read_when:
  - 你想讓 agent 以 diff 方式顯示程式碼或 markdown 編輯
  - 你想要一個適合 canvas 的檢視器 URL 或渲染的 diff 檔案
  - 你需要帶有安全預設值的受控、暫時性 diff artifacts
---

# Diffs

`diffs` 是一個選用的 plugin 工具，內建簡短的系統引導，並附有一個輔助 skill，可將變更內容轉換為 agent 的唯讀 diff artifact。

它接受以下其中一種輸入：

- `before` 和 `after` 文字
- 統一 `patch`

它可以回傳：

- 用於 canvas 呈現的 gateway 檢視器 URL
- 渲染的檔案路徑（PNG 或 PDF）用於訊息傳遞
- 在一次呼叫中同時輸出兩者

啟用後，plugin 會將簡潔的使用說明前置至 system prompt 空間，並為 agent 需要更完整指示的情況公開一個詳細的 skill。

## 快速上手

1. 啟用 plugin。
2. 呼叫 `diffs` 加 `mode: "view"` 用於 canvas 優先的流程。
3. 呼叫 `diffs` 加 `mode: "file"` 用於聊天檔案傳遞流程。
4. 呼叫 `diffs` 加 `mode: "both"` 當你需要兩種 artifacts 時。

## 啟用 plugin

```json5
{
  plugins: {
    entries: {
      diffs: {
        enabled: true,
      },
    },
  },
}
```

## 停用內建系統引導

若你想保持 `diffs` 工具啟用但停用其內建 system prompt 引導，將 `plugins.entries.diffs.hooks.allowPromptInjection` 設為 `false`：

```json5
{
  plugins: {
    entries: {
      diffs: {
        enabled: true,
        hooks: {
          allowPromptInjection: false,
        },
      },
    },
  },
}
```

這會封鎖 diffs plugin 的 `before_prompt_build` hook，同時保持 plugin、工具和輔助 skill 可用。

若要同時停用引導和工具，改為停用 plugin。

## 典型 agent 工作流程

1. Agent 呼叫 `diffs`。
2. Agent 讀取 `details` 欄位。
3. Agent 選擇：
   - 以 `canvas present` 開啟 `details.viewerUrl`
   - 以 `message` 使用 `path` 或 `filePath` 傳送 `details.filePath`
   - 兩者都做

## 輸入範例

前後比較：

```json
{
  "before": "# Hello\n\nOne",
  "after": "# Hello\n\nTwo",
  "path": "docs/example.md",
  "mode": "view"
}
```

Patch：

```json
{
  "patch": "diff --git a/src/example.ts b/src/example.ts\n--- a/src/example.ts\n+++ b/src/example.ts\n@@ -1 +1 @@\n-const x = 1;\n+const x = 2;\n",
  "mode": "both"
}
```

## 工具輸入參考

所有欄位除非另有說明皆為選用：

- `before`（`string`）：原始文字。省略 `patch` 時與 `after` 一起必填。
- `after`（`string`）：更新後的文字。省略 `patch` 時與 `before` 一起必填。
- `patch`（`string`）：統一 diff 文字。與 `before` 和 `after` 互斥。
- `path`（`string`）：前後比較模式的顯示檔名。
- `lang`（`string`）：前後比較模式的語言覆寫提示。
- `title`（`string`）：檢視器標題覆寫。
- `mode`（`"view" | "file" | "both"`）：輸出模式。預設為 plugin 預設 `defaults.mode`。
- `theme`（`"light" | "dark"`）：檢視器主題。預設為 plugin 預設 `defaults.theme`。
- `layout`（`"unified" | "split"`）：diff 佈局。預設為 plugin 預設 `defaults.layout`。
- `expandUnchanged`（`boolean`）：完整 context 可用時展開未更改的區段。僅限每次呼叫的選項（非 plugin 預設 key）。
- `fileFormat`（`"png" | "pdf"`）：渲染的檔案格式。預設為 plugin 預設 `defaults.fileFormat`。
- `fileQuality`（`"standard" | "hq" | "print"`）：PNG 或 PDF 渲染的品質預設。
- `fileScale`（`number`）：裝置縮放覆寫（`1`-`4`）。
- `fileMaxWidth`（`number`）：最大渲染寬度（CSS 像素，`640`-`2400`）。
- `ttlSeconds`（`number`）：檢視器 artifact TTL（秒）。預設 1800，最大 21600。
- `baseUrl`（`string`）：檢視器 URL 來源覆寫。必須為 `http` 或 `https`，不含 query/hash。

驗證和限制：

- `before` 和 `after` 各最大 512 KiB。
- `patch` 最大 2 MiB。
- `path` 最大 2048 bytes。
- `lang` 最大 128 bytes。
- `title` 最大 1024 bytes。
- Patch 複雜度上限：最多 128 個檔案和 120000 行。
- 不可同時提供 `patch` 和 `before` 或 `after`。
- 渲染檔案安全限制（適用於 PNG 和 PDF）：
  - `fileQuality: "standard"`：最大 8 MP（8,000,000 渲染像素）。
  - `fileQuality: "hq"`：最大 14 MP（14,000,000 渲染像素）。
  - `fileQuality: "print"`：最大 24 MP（24,000,000 渲染像素）。
  - PDF 另有最多 50 頁的限制。

## 輸出詳情合約

工具在 `details` 下回傳結構化元資料。

建立檢視器的模式的共用欄位：

- `artifactId`
- `viewerUrl`
- `viewerPath`
- `title`
- `expiresAt`
- `inputKind`
- `fileCount`
- `mode`

渲染 PNG 或 PDF 時的檔案欄位：

- `filePath`
- `path`（與 `filePath` 相同，用於 message 工具相容性）
- `fileBytes`
- `fileFormat`
- `fileQuality`
- `fileScale`
- `fileMaxWidth`

模式行為摘要：

- `mode: "view"`：僅檢視器欄位。
- `mode: "file"`：僅檔案欄位，無檢視器 artifact。
- `mode: "both"`：檢視器欄位加檔案欄位。若檔案渲染失敗，檢視器仍回傳並附帶 `fileError`。

## 折疊未更改的區段

- 檢視器可以顯示「N 個未修改的行」的行。
- 這些行的展開控制項是有條件的，並非每種輸入類型都有保證。
- 當渲染的 diff 具有可展開的 context 資料時，展開控制項才會出現，這在前後比較輸入中很典型。
- 對於許多統一 patch 輸入，已省略的 context 正文在解析的 patch hunks 中無法取得，因此行可能不帶展開控制項。這是預期行為。
- `expandUnchanged` 僅在可展開的 context 存在時才適用。

## Plugin 預設值

在 `~/.openclaw/openclaw.json` 中設定 plugin 範圍的預設值：

```json5
{
  plugins: {
    entries: {
      diffs: {
        enabled: true,
        config: {
          defaults: {
            fontFamily: "Fira Code",
            fontSize: 15,
            lineSpacing: 1.6,
            layout: "unified",
            showLineNumbers: true,
            diffIndicators: "bars",
            wordWrap: true,
            background: true,
            theme: "dark",
            fileFormat: "png",
            fileQuality: "standard",
            fileScale: 2,
            fileMaxWidth: 960,
            mode: "both",
          },
        },
      },
    },
  },
}
```

支援的預設值：

- `fontFamily`
- `fontSize`
- `lineSpacing`
- `layout`
- `showLineNumbers`
- `diffIndicators`
- `wordWrap`
- `background`
- `theme`
- `fileFormat`
- `fileQuality`
- `fileScale`
- `fileMaxWidth`
- `mode`

明確的工具參數會覆寫這些預設值。

## 安全設定

- `security.allowRemoteViewer`（`boolean`，預設 `false`）
  - `false`：對檢視器路由的非 loopback 請求被拒絕。
  - `true`：若 tokenized 路徑有效，則允許遠端檢視器。

範例：

```json5
{
  plugins: {
    entries: {
      diffs: {
        enabled: true,
        config: {
          security: {
            allowRemoteViewer: false,
          },
        },
      },
    },
  },
}
```

## Artifact 生命週期和儲存

- Artifacts 儲存在臨時子目錄下：`$TMPDIR/openclaw-diffs`。
- 檢視器 artifact 元資料包含：
  - 隨機 artifact ID（20 個十六進位字元）
  - 隨機 token（48 個十六進位字元）
  - `createdAt` 和 `expiresAt`
  - 儲存的 `viewer.html` 路徑
- 未指定時，預設檢視器 TTL 為 30 分鐘。
- 最大接受的檢視器 TTL 為 6 小時。
- 清理在 artifact 建立後隨機執行。
- 已過期的 artifacts 被刪除。
- 備用清理會在元資料遺失時移除超過 24 小時的過時目錄。

## 檢視器 URL 和網路行為

檢視器路由：

- `/plugins/diffs/view/{artifactId}/{token}`

檢視器資源：

- `/plugins/diffs/assets/viewer.js`
- `/plugins/diffs/assets/viewer-runtime.js`

URL 建構行為：

- 若提供 `baseUrl`，在嚴格驗證後使用它。
- 若無 `baseUrl`，檢視器 URL 預設為 loopback `127.0.0.1`。
- 若 gateway 綁定模式為 `custom` 且已設定 `gateway.customBindHost`，則使用該 host。

`baseUrl` 規則：

- 必須為 `http://` 或 `https://`。
- 拒絕 query 和 hash。
- 允許 origin 加可選基礎路徑。

## 安全模型

檢視器加固：

- 預設僅限 loopback。
- Tokenized 檢視器路徑，嚴格的 ID 和 token 驗證。
- 檢視器回應 CSP：
  - `default-src 'none'`
  - 指令碼和資源僅來自 self
  - 無對外 `connect-src`
- 啟用遠端存取時的遠端未命中節流：
  - 每 60 秒 40 次失敗
  - 60 秒鎖定（`429 Too Many Requests`）

檔案渲染加固：

- 截圖瀏覽器請求路由預設拒絕。
- 僅允許來自 `http://127.0.0.1/plugins/diffs/assets/*` 的本地檢視器資源。
- 封鎖外部網路請求。

## 檔案模式的瀏覽器需求

`mode: "file"` 和 `mode: "both"` 需要 Chromium 相容的瀏覽器。

解析順序：

1. OpenClaw 設定中的 `browser.executablePath`。
2. 環境變數：
   - `OPENCLAW_BROWSER_EXECUTABLE_PATH`
   - `BROWSER_EXECUTABLE_PATH`
   - `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`
3. 平台命令/路徑探索備用。

常見失敗文字：

- `Diff PNG/PDF rendering requires a Chromium-compatible browser...`

透過安裝 Chrome、Chromium、Edge 或 Brave，或設定上述可執行路徑選項之一來修復。

## 疑難排解

輸入驗證錯誤：

- `Provide patch or both before and after text.`
  - 同時提供 `before` 和 `after`，或提供 `patch`。
- `Provide either patch or before/after input, not both.`
  - 不要混用輸入模式。
- `Invalid baseUrl: ...`
  - 使用 `http(s)` origin 加可選路徑，不含 query/hash。
- `{field} exceeds maximum size (...)`
  - 減少 payload 大小。
- 大型 patch 被拒絕
  - 減少 patch 檔案數量或總行數。

檢視器可存取性問題：

- 檢視器 URL 預設解析至 `127.0.0.1`。
- 對於遠端存取場景，可以：
  - 每次工具呼叫傳遞 `baseUrl`，或
  - 使用 `gateway.bind=custom` 和 `gateway.customBindHost`
- 僅在打算讓外部存取檢視器時啟用 `security.allowRemoteViewer`。

未修改行沒有展開按鈕：

- 當 patch 不帶可展開 context 時，這可能發生於 patch 輸入。
- 這是預期行為，不表示檢視器故障。

Artifact 未找到：

- Artifact 因 TTL 已過期。
- Token 或路徑已更改。
- 清理移除了過時資料。

## 操作指引

- 優先使用 `mode: "view"` 用於 canvas 中的本地互動審查。
- 優先使用 `mode: "file"` 用於需要附件的對外聊天頻道。
- 除非你的部署需要遠端檢視器 URL，否則保持 `allowRemoteViewer` 停用。
- 對敏感 diffs 設定明確的短 `ttlSeconds`。
- 不需要時避免在 diff 輸入中傳送機密資訊。
- 若你的頻道積極壓縮圖片（例如 Telegram 或 WhatsApp），優先使用 PDF 輸出（`fileFormat: "pdf"`）。

Diff 渲染引擎：

- 由 [Diffs](https://diffs.com) 提供支援。

## 相關文件

- [Tools overview](/zh-Hant/tools)
- [Plugins](/zh-Hant/tools/plugin)
- [Browser](/zh-Hant/tools/browser)
