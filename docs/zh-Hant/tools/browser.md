---
summary: "整合式瀏覽器控制服務 + 動作指令"
read_when:
  - 新增 Agent 控制的瀏覽器自動化
  - 偵錯為何 openclaw 干擾您自己的 Chrome
  - 在 macOS 應用程式中實現瀏覽器設定 + 生命週期
title: "Browser (OpenClaw-managed)"
---

# Browser (openclaw-managed)

OpenClaw 可以執行一個**專屬的 Chrome/Brave/Edge/Chromium 設定檔**，由 Agent 控制。
它與您的個人瀏覽器隔離，由 Gateway 內部的小型本地控制服務管理（僅限迴路）。

初級檢視：

- 將其視為**獨立的、Agent 專用的瀏覽器**。
- `openclaw` 設定檔**不會**觸及您的個人瀏覽器設定檔。
- Agent 可以**開啟分頁、讀取頁面、點擊和輸入**在安全通道中。
- 預設 `chrome` 設定檔透過擴充功能轉發使用**系統預設 Chromium 瀏覽器**；切換到 `openclaw` 以取得隔離的受管瀏覽器。

## 您得到什麼

- 一個名為 **openclaw** 的獨立瀏覽器設定檔（預設橙色口音）。
- 確定性的分頁控制（清單/開啟/焦點/關閉）。
- Agent 動作（點擊/輸入/拖曳/選擇）、快照、螢幕擷取、PDF。
- 選用的多設定檔支援（`openclaw`、`work`、`remote`、...）。

此瀏覽器**不是**您的日常驅動程式。它是 Agent 自動化和驗證的安全、隔離表面。

## 快速開始

```bash
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw start
openclaw browser --browser-profile openclaw open https://example.com
openclaw browser --browser-profile openclaw snapshot
```

如果您得到「Browser disabled」，在 config 中啟用它（見下方）並重新啟動 Gateway。

## 設定檔：`openclaw` vs `chrome`

- `openclaw`：受管、隔離的瀏覽器（不需要擴充功能）。
- `chrome`：擴充功能轉發您的**系統瀏覽器**（需要 OpenClaw 擴充功能附加到分頁）。

如果您想預設使用受管模式，請設定 `browser.defaultProfile: "openclaw"`。

## 組態

瀏覽器設定位於 `~/.openclaw/openclaw.json`。

```json5
{
  browser: {
    enabled: true, // 預設：true
    // cdpUrl: "http://127.0.0.1:18792", // 舊版單設定檔覆寫
    remoteCdpTimeoutMs: 1500, // 遠端 CDP HTTP 逾時 (ms)
    remoteCdpHandshakeTimeoutMs: 3000, // 遠端 CDP WebSocket 握手逾時 (ms)
    defaultProfile: "chrome",
    color: "#FF4500",
    headless: false,
    noSandbox: false,
    attachOnly: false,
    executablePath: "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    profiles: {
      openclaw: { cdpPort: 18800, color: "#FF4500" },
      work: { cdpPort: 18801, color: "#0066CC" },
      remote: { cdpUrl: "http://10.0.0.42:9222", color: "#00AA00" },
    },
  },
}
```

注意：

- 瀏覽器控制服務綁定到從 `gateway.port` 衍生的迴路連接埠
  （預設：`18791`，即 gateway + 2）。轉發使用下一個連接埠（`18792`）。
- 如果您覆寫 Gateway 連接埠（`gateway.port` 或 `OPENCLAW_GATEWAY_PORT`），
  衍生的瀏覽器連接埠會轉移以保持在同一「系列」中。
- `cdpUrl` 未設定時預設為轉發連接埠。
- `remoteCdpTimeoutMs` 適用於遠端（非迴路）CDP 可達性檢查。
- `remoteCdpHandshakeTimeoutMs` 適用於遠端 CDP WebSocket 可達性檢查。
- `attachOnly: true` 表示「永不啟動本地瀏覽器；只有在已執行時才附加」。
- `color` + 每個設定檔的 `color` 會給瀏覽器 UI 著色，讓您可以看到哪個設定檔處於作用中。
- 預設設定檔是 `chrome`（擴充功能轉發）。使用 `defaultProfile: "openclaw"` 以取得受管瀏覽器。
- 自動偵測順序：如果是 Chromium 型，則使用系統預設瀏覽器；否則 Chrome → Brave → Edge → Chromium → Chrome Canary。
- 本地 `openclaw` 設定檔會自動指定 `cdpPort`/`cdpUrl` — 只為遠端 CDP 設定那些。

## 使用 Brave（或另一個 Chromium 型瀏覽器）

如果您的**系統預設**瀏覽器是 Chromium 型（Chrome/Brave/Edge/等），
OpenClaw 會自動使用它。設定 `browser.executablePath` 以覆寫
自動偵測：

CLI 範例：

```bash
openclaw config set browser.executablePath "/usr/bin/google-chrome"
```

```json5
// macOS
{
  browser: {
    executablePath: "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
  }
}

// Windows
{
  browser: {
    executablePath: "C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe"
  }
}

// Linux
{
  browser: {
    executablePath: "/usr/bin/brave-browser"
  }
}
```

## 本地 vs 遠端控制

- **本地控制（預設）**：Gateway 啟動迴路控制服務且可啟動本地瀏覽器。
- **遠端控制（node host）**：在擁有瀏覽器的機器上執行 node host；Gateway 代理瀏覽器動作。
- **遠端 CDP**：設定 `browser.profiles.<name>.cdpUrl`（或 `browser.cdpUrl`）以
  附加到遠端 Chromium 型瀏覽器。在此情況下，OpenClaw 不會啟動本地瀏覽器。

遠端 CDP URL 可以包含身份驗證：

- 查詢權杖（例如，`https://provider.example?token=<token>`）
- HTTP Basic auth（例如，`https://user:pass@provider.example`）

OpenClaw 會在呼叫 `/json/*` 端點和連接到 CDP WebSocket 時保留身份驗證。對於權杖，最好使用環境變數或祕密管理器，而不是將它們認可到 config 檔案。

## Node 瀏覽器代理（零設定預設）

如果您在擁有瀏覽器的機器上執行**node host**，OpenClaw 可以
自動將瀏覽器工具呼叫路由至該節點，而不需要任何額外的瀏覽器 config。
這是遠端 gateway 的預設路徑。

注意：

- Node host 透過**代理指令**公開其本地瀏覽器控制伺服器。
- 設定檔來自節點自己的 `browser.profiles` config（與本地相同）。
- 如果您不想要，請停用：
  - 在節點上：`nodeHost.browserProxy.enabled=false`
  - 在 gateway 上：`gateway.nodes.browser.mode="off"`

## Browserless（託管遠端 CDP）

[Browserless](https://browserless.io) 是一項託管的 Chromium 服務，透過 HTTPS 公開
CDP 端點。您可以將 OpenClaw 瀏覽器設定檔指向
Browserless 區域端點並使用您的 API 金鑰進行身份驗證。

範例：

```json5
{
  browser: {
    enabled: true,
    defaultProfile: "browserless",
    remoteCdpTimeoutMs: 2000,
    remoteCdpHandshakeTimeoutMs: 4000,
    profiles: {
      browserless: {
        cdpUrl: "https://production-sfo.browserless.io?token=<BROWSERLESS_API_KEY>",
        color: "#00AA00",
      },
    },
  },
}
```

注意：

- 使用您的真實 Browserless 權杖取代 `<BROWSERLESS_API_KEY>`。
- 選擇與您的 Browserless 帳戶相符的區域端點（見他們的文件）。

## 安全性

重點概念：

- 瀏覽器控制僅限迴路；存取透過 Gateway 的身份驗證或節點配對流動。
- 將 Gateway 和任何 node host 保持在私有網路上（Tailscale）；避免公開公開。
- 將遠端 CDP URL/權杖視為祕密；最好使用環境變數或祕密管理器。

遠端 CDP 提示：

- 盡可能偏好 HTTPS 端點和短生命的權杖。
- 避免將長期權杖直接內嵌在 config 檔案中。

## 設定檔（多瀏覽器）

OpenClaw 支援多個具名設定檔（路由 config）。設定檔可以是：

- **openclaw 受管**：具有自己的使用者資料目錄 + CDP 連接埠的專屬 Chromium 型瀏覽器執行個體
- **遠端**：明確的 CDP URL（在其他位置執行的 Chromium 型瀏覽器）
- **擴充功能轉發**：透過本地轉發 + Chrome 擴充功能的您現有的 Chrome 分頁

預設值：

- `openclaw` 設定檔會在遺漏時自動建立。
- `chrome` 設定檔是為 Chrome 擴充功能轉發內建（預設指向 `http://127.0.0.1:18792`）。
- 本地 CDP 連接埠預設從 **18800–18899** 配置。
- 刪除設定檔會將其本地資料目錄移到垃圾筒。

所有控制端點接受 `?profile=<name>`；CLI 使用 `--browser-profile`。

## Chrome 擴充功能轉發（使用您現有的 Chrome）

OpenClaw 也可以透過本地 CDP 轉發 + Chrome 擴充功能驅動**您現有的 Chrome 分頁**（無獨立的「openclaw」Chrome 執行個體）。

完整指南：[Chrome extension](/tools/chrome-extension)

流程：

- Gateway 在本地執行（同一機器）或 node host 在瀏覽器機器上執行。
- 本地**轉發伺服器**在迴路 `cdpUrl` 上監聽（預設：`http://127.0.0.1:18792`）。
- 您在分頁上按一下 **OpenClaw Browser Relay** 擴充功能圖示以附加（它不會自動附加）。
- Agent 透過正常 `browser` 工具控制該分頁，方式為選擇正確的設定檔。

如果 Gateway 在其他位置執行，在瀏覽器機器上執行 node host，讓 Gateway 可以代理瀏覽器動作。

### 沙盒化會話

如果 Agent 會話沙盒化，`browser` 工具可能會預設為 `target="sandbox"`（沙盒瀏覽器）。
Chrome 擴充功能轉發接管需要 host 瀏覽器控制，所以任一：

- 執行未沙盒化會話，或
- 設定 `agents.defaults.sandbox.browser.allowHostControl: true` 並在呼叫工具時使用 `target="host"`。

### 設定

1. 載入擴充功能（開發/未打包）：

```bash
openclaw browser extension install
```

- Chrome → `chrome://extensions` → 啟用「Developer mode」
- 「Load unpacked」→ 選擇 `openclaw browser extension path` 列印的目錄
- 釘選擴充功能，然後在您想控制的分頁上按一下它（徽章顯示 `ON`）。

2. 使用它：

- CLI：`openclaw browser --browser-profile chrome tabs`
- Agent 工具：`browser` 與 `profile="chrome"`

選用：如果您想要不同的名稱或轉發連接埠，建立您自己的設定檔：

```bash
openclaw browser create-profile \
  --name my-chrome \
  --driver extension \
  --cdp-url http://127.0.0.1:18792 \
  --color "#00AA00"
```

注意：

- 此模式針對大多數操作（螢幕擷取/快照/動作）依賴 Playwright-on-CDP。
- 透過再次按一下擴充功能圖示來分離。

## 隔離保證

- **專屬使用者資料目錄**：永不觸及您的個人瀏覽器設定檔。
- **專屬連接埠**：避免 `9222` 以防止與開發工作流衝突。
- **確定性分頁控制**：按 `targetId` 目標分頁，而非「最後一個分頁」。

## 瀏覽器選擇

本地啟動時，OpenClaw 選擇首先可用的：

1. Chrome
2. Brave
3. Edge
4. Chromium
5. Chrome Canary

您可以使用 `browser.executablePath` 覆寫。

平台：

- macOS：檢查 `/Applications` 和 `~/Applications`。
- Linux：尋找 `google-chrome`、`brave`、`microsoft-edge`、`chromium` 等。
- Windows：檢查一般安裝位置。

## 控制 API（選用）

對於本地整合，Gateway 公開一個小型迴路 HTTP API：

- 狀態/啟動/停止：`GET /`、`POST /start`、`POST /stop`
- 分頁：`GET /tabs`、`POST /tabs/open`、`POST /tabs/focus`、`DELETE /tabs/:targetId`
- 快照/螢幕擷取：`GET /snapshot`、`POST /screenshot`
- 動作：`POST /navigate`、`POST /act`
- 掛勾：`POST /hooks/file-chooser`、`POST /hooks/dialog`
- 下載：`POST /download`、`POST /wait/download`
- 偵錯：`GET /console`、`POST /pdf`
- 偵錯：`GET /errors`、`GET /requests`、`POST /trace/start`、`POST /trace/stop`、`POST /highlight`
- 網路：`POST /response/body`
- 狀態：`GET /cookies`、`POST /cookies/set`、`POST /cookies/clear`
- 狀態：`GET /storage/:kind`、`POST /storage/:kind/set`、`POST /storage/:kind/clear`
- 設定：`POST /set/offline`、`POST /set/headers`、`POST /set/credentials`、`POST /set/geolocation`、`POST /set/media`、`POST /set/timezone`、`POST /set/locale`、`POST /set/device`

所有端點接受 `?profile=<name>`。

### Playwright 需求

某些功能（導覽/動作/AI 快照/角色快照、元素螢幕擷取、PDF）需要
Playwright。如果未安裝 Playwright，那些端點會回傳清楚的 501
錯誤。ARIA 快照和基本螢幕擷取仍對 openclaw 受管 Chrome 有效。
對於 Chrome 擴充功能轉發驅動程式，ARIA 快照和螢幕擷取需要 Playwright。

如果您看到 `Playwright is not available in this gateway build`，安裝完整的
Playwright 套件（不是 `playwright-core`）並重新啟動 gateway，或重新安裝
OpenClaw 加上瀏覽器支援。

#### Docker Playwright 安裝

如果您的 Gateway 在 Docker 中執行，避免 `npx playwright`（npm 覆寫衝突）。
改為使用已組合的 CLI：

```bash
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

要保留瀏覽器下載，請設定 `PLAYWRIGHT_BROWSERS_PATH`（例如，
`/home/node/.cache/ms-playwright`）並確保 `/home/node` 透過
`OPENCLAW_HOME_VOLUME` 或綁定掛載保留。見 [Docker](/install/docker)。

## 運作方式（內部）

高階流程：

- 一個小型**控制伺服器**接受 HTTP 要求。
- 它透過 **CDP** 連接到 Chromium 型瀏覽器（Chrome/Brave/Edge/Chromium）。
- 對於進階動作（點擊/輸入/快照/PDF），它在 CDP 頂部使用 **Playwright**。
- 當 Playwright 遺漏時，只有非 Playwright 操作可用。

此設計讓 Agent 在穩定、確定性的介面上，同時讓您
交換本地/遠端瀏覽器和設定檔。

## CLI 快速參考

所有指令接受 `--browser-profile <name>` 以指定特定設定檔。
所有指令也接受 `--json` 以取得機器可讀的輸出（穩定裝載）。

基礎：

- `openclaw browser status`
- `openclaw browser start`
- `openclaw browser stop`
- `openclaw browser tabs`
- `openclaw browser tab`
- `openclaw browser tab new`
- `openclaw browser tab select 2`
- `openclaw browser tab close 2`
- `openclaw browser open https://example.com`
- `openclaw browser focus abcd1234`
- `openclaw browser close abcd1234`

檢查：

- `openclaw browser screenshot`
- `openclaw browser screenshot --full-page`
- `openclaw browser screenshot --ref 12`
- `openclaw browser screenshot --ref e12`
- `openclaw browser snapshot`
- `openclaw browser snapshot --format aria --limit 200`
- `openclaw browser snapshot --interactive --compact --depth 6`
- `openclaw browser snapshot --efficient`
- `openclaw browser snapshot --labels`
- `openclaw browser snapshot --selector "#main" --interactive`
- `openclaw browser snapshot --frame "iframe#main" --interactive`
- `openclaw browser console --level error`
- `openclaw browser errors --clear`
- `openclaw browser requests --filter api --clear`
- `openclaw browser pdf`
- `openclaw browser responsebody "**/api" --max-chars 5000`

動作：

- `openclaw browser navigate https://example.com`
- `openclaw browser resize 1280 720`
- `openclaw browser click 12 --double`
- `openclaw browser click e12 --double`
- `openclaw browser type 23 "hello" --submit`
- `openclaw browser press Enter`
- `openclaw browser hover 44`
- `openclaw browser scrollintoview e12`
- `openclaw browser drag 10 11`
- `openclaw browser select 9 OptionA OptionB`
- `openclaw browser download e12 /tmp/report.pdf`
- `openclaw browser waitfordownload /tmp/report.pdf`
- `openclaw browser upload /tmp/file.pdf`
- `openclaw browser fill --fields '[{"ref":"1","type":"text","value":"Ada"}]'`
- `openclaw browser dialog --accept`
- `openclaw browser wait --text "Done"`
- `openclaw browser wait "#main" --url "**/dash" --load networkidle --fn "window.ready===true"`
- `openclaw browser evaluate --fn '(el) => el.textContent' --ref 7`
- `openclaw browser highlight e12`
- `openclaw browser trace start`
- `openclaw browser trace stop`

狀態：

- `openclaw browser cookies`
- `openclaw browser cookies set session abc123 --url "https://example.com"`
- `openclaw browser cookies clear`
- `openclaw browser storage local get`
- `openclaw browser storage local set theme dark`
- `openclaw browser storage session clear`
- `openclaw browser set offline on`
- `openclaw browser set headers --json '{"X-Debug":"1"}'`
- `openclaw browser set credentials user pass`
- `openclaw browser set credentials --clear`
- `openclaw browser set geo 37.7749 -122.4194 --origin "https://example.com"`
- `openclaw browser set geo --clear`
- `openclaw browser set media dark`
- `openclaw browser set timezone America/New_York`
- `openclaw browser set locale en-US`
- `openclaw browser set device "iPhone 14"`

注意：

- `upload` 和 `dialog` 是**武裝**呼叫；在觸發選擇器/對話方塊的點擊/按下前執行它們。
- `upload` 也可以透過 `--input-ref` 或 `--element` 直接設定檔案輸入。
- `snapshot`：
  - `--format ai`（安裝 Playwright 時的預設）：回傳帶有數字 refs 的 AI 快照（`aria-ref="<n>"`）。
  - `--format aria`：回傳輔助功能樹（無 refs；僅檢查）。
  - `--efficient`（或 `--mode efficient`）：緊湊角色快照預設（interactive + compact + depth + 較低 maxChars）。
  - Config 預設（工具/CLI 僅）：設定 `browser.snapshotDefaults.mode: "efficient"` 以在呼叫者未傳遞模式時使用有效快照（見 [Gateway configuration](/gateway/configuration#browser-openclaw-managed-browser)）。
  - 角色快照選項（`--interactive`、`--compact`、`--depth`、`--selector`）會強制進行帶有 `ref=e12` 等 refs 的基於角色的快照。
  - `--frame "<iframe selector>"` 將角色快照範圍限制在 iframe（與 `e12` 等角色 refs 配對）。
  - `--interactive` 輸出互動元素的平面、容易挑選清單（最適合驅動動作）。
  - `--labels` 新增帶有覆蓋 ref 標籤的僅限檢視區螢幕擷取（列印 `MEDIA:<path>`）。
- `click`/`type`/等需要來自 `snapshot` 的 `ref`（數字 `12` 或角色 ref `e12`）。
  CSS 選擇器已刻意不支援動作。

## 快照和 refs

OpenClaw 支援兩個「快照」風格：

- **AI 快照（數字 refs）**：`openclaw browser snapshot`（預設；`--format ai`）
  - 輸出：包含數字 refs 的文字快照。
  - 動作：`openclaw browser click 12`、`openclaw browser type 23 "hello"`。
  - 內部，ref 透過 Playwright 的 `aria-ref` 解析。

- **角色快照（`e12` 等角色 refs）**：`openclaw browser snapshot --interactive`（或 `--compact`、`--depth`、`--selector`、`--frame`）
  - 輸出：帶有 `[ref=e12]`（以及選用 `[nth=1]`）的基於角色的清單/樹。
  - 動作：`openclaw browser click e12`、`openclaw browser highlight e12`。
  - 內部，ref 透過 `getByRole(...)`（加上 `nth()` 用於重複）解析。
  - 新增 `--labels` 以包含帶有覆蓋 `e12` 標籤的檢視區螢幕擷取。

Ref 行為：

- Refs **不會在導覽間穩定**；如果某事失敗，重新執行 `snapshot` 並使用新的 ref。
- 如果角色快照是使用 `--frame` 取得，角色 refs 會限定於該 iframe，直到下一個角色快照。

## 等待強化功能

您可以等待超過只是時間/文字：

- 等待 URL（Playwright 支援萬用字元）：
  - `openclaw browser wait --url "**/dash"`
- 等待載入狀態：
  - `openclaw browser wait --load networkidle`
- 等待 JS 述詞：
  - `openclaw browser wait --fn "window.ready===true"`
- 等待選擇器變成可見：
  - `openclaw browser wait "#main"`

這些可以組合：

```bash
openclaw browser wait "#main" \
  --url "**/dash" \
  --load networkidle \
  --fn "window.ready===true" \
  --timeout-ms 15000
```

## 偵錯工作流程

當動作失敗時（例如「不可見」、「strict mode violation」、「covered」）：

1. `openclaw browser snapshot --interactive`
2. 使用 `click <ref>` / `type <ref>`（在互動模式中偏好角色 refs）
3. 如果仍失敗：`openclaw browser highlight <ref>` 以查看 Playwright 指定的內容
4. 如果頁面行為異常：
   - `openclaw browser errors --clear`
   - `openclaw browser requests --filter api --clear`
5. 用於深度偵錯：記錄追蹤：
   - `openclaw browser trace start`
   - 重現問題
   - `openclaw browser trace stop`（列印 `TRACE:<path>`）

## JSON 輸出

`--json` 用於指令碼和結構化工具。

範例：

```bash
openclaw browser status --json
openclaw browser snapshot --interactive --json
openclaw browser requests --filter api --json
openclaw browser cookies --json
```

JSON 中的角色快照包含 `refs` 加上一個小型 `stats` 區塊（lines/chars/refs/interactive），讓工具可以推理裝載大小和密度。

## 狀態和環境旋鈕

這些對「讓網站表現得像 X」工作流程很有用：

- Cookies：`cookies`、`cookies set`、`cookies clear`
- Storage：`storage local|session get|set|clear`
- 離線：`set offline on|off`
- Headers：`set headers --json '{"X-Debug":"1"}'`（或 `--clear`）
- HTTP basic auth：`set credentials user pass`（或 `--clear`）
- 地理位置：`set geo <lat> <lon> --origin "https://example.com"`（或 `--clear`）
- 媒體：`set media dark|light|no-preference|none`
- 時區/語言環境：`set timezone ...`、`set locale ...`
- 裝置/檢視區：
  - `set device "iPhone 14"`（Playwright 裝置預設）
  - `set viewport 1280 720`

## 安全和隱私

- openclaw 瀏覽器設定檔可能包含登入後的會話；將其視為敏感資料。
- `browser act kind=evaluate` / `openclaw browser evaluate` 和 `wait --fn`
  在頁面內容中執行任意 JavaScript。提示注射可以轉向
  這。如果不需要，使用 `browser.evaluateEnabled=false` 停用它。
- 對於登入和反機器人注意（X/Twitter 等），見 [Browser login + X/Twitter posting](/tools/browser-login)。
- 讓 Gateway/node host 保持私有（迴路或僅限 tailnet）。
- 遠端 CDP 端點很強大；對其進行隧道和保護。

## 疑難排解

對於 Linux 特定的問題（特別是 snap Chromium），見
[Browser troubleshooting](/tools/browser-linux-troubleshooting)。

## Agent 工具 + 控制運作方式

Agent 取得**一個工具**用於瀏覽器自動化：

- `browser` — status/start/stop/tabs/open/focus/close/snapshot/screenshot/navigate/act

它如何對應：

- `browser snapshot` 回傳穩定的 UI 樹（AI 或 ARIA）。
- `browser act` 使用快照 `ref` ID 進行點擊/輸入/拖曳/選擇。
- `browser screenshot` 擷取像素（完整頁面或元素）。
- `browser` 接受：
  - `profile` 以選擇具名瀏覽器設定檔（openclaw、chrome 或遠端 CDP）。
  - `target`（`sandbox` | `host` | `node`）以選擇瀏覽器位於何處。
  - 在沙盒化會話中，`target: "host"` 需要 `agents.defaults.sandbox.browser.allowHostControl=true`。
  - 如果 `target` 被省略：沙盒化會話預設為 `sandbox`，非沙盒會話預設為 `host`。
  - 如果已連接具備瀏覽器能力的節點，工具可能會自動路由至它，除非您釘選 `target="host"` 或 `target="node"`。

這讓 Agent 保持確定性並避免脆弱的選擇器。
