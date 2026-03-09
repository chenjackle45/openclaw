---
summary: "整合瀏覽器控制服務 + 動作命令"
read_when:
  - 新增 agent 控制的瀏覽器自動化
  - 偵錯為何 openclaw 干擾你自己的 Chrome
  - 在 macOS app 中實作瀏覽器設定和生命週期
title: "Browser (OpenClaw-managed)（OpenClaw 管理的瀏覽器）"
---

# Browser (openclaw-managed)

OpenClaw 可以執行一個 **專屬的 Chrome/Brave/Edge/Chromium profile**，由 agent 控制。
它與你的個人瀏覽器隔離，並透過 Gateway 內部的小型本地控制服務（僅限 loopback）管理。

入門概覽：

- 把它想成一個 **專屬的、只供 agent 使用的瀏覽器**。
- `openclaw` profile **不會**碰你的個人瀏覽器 profile。
- Agent 可以在安全的通道中**開啟分頁、讀取頁面、點擊和輸入**。
- 預設 `chrome` profile 透過 extension relay 使用**系統預設的 Chromium 瀏覽器**；切換至 `openclaw` 可使用隔離的受管瀏覽器。

## 你將獲得什麼

- 一個名為 **openclaw** 的獨立瀏覽器 profile（預設橘色強調色）。
- 確定性的分頁控制（列出/開啟/聚焦/關閉）。
- Agent 動作（點擊/輸入/拖曳/選取）、快照、截圖、PDF。
- 選用的多 profile 支援（`openclaw`、`work`、`remote`……）。

此瀏覽器**不是**你的日常瀏覽器。它是用於 agent 自動化和驗證的安全隔離介面。

## 快速上手

```bash
openclaw browser --browser-profile openclaw status
openclaw browser --browser-profile openclaw start
openclaw browser --browser-profile openclaw open https://example.com
openclaw browser --browser-profile openclaw snapshot
```

如果收到「Browser disabled」，請在設定中啟用（見下方）並重啟 Gateway。

## Profiles：`openclaw` 與 `chrome`

- `openclaw`：受管隔離瀏覽器（不需要 extension）。
- `chrome`：透過 extension relay 連至你的**系統瀏覽器**（需要 OpenClaw extension 附加至分頁）。

若要預設使用受管模式，設定 `browser.defaultProfile: "openclaw"`。

## 設定

瀏覽器設定位於 `~/.openclaw/openclaw.json`。

```json5
{
  browser: {
    enabled: true, // 預設：true
    ssrfPolicy: {
      dangerouslyAllowPrivateNetwork: true, // 預設信任網路模式
      // allowPrivateNetwork: true, // 舊版別名
      // hostnameAllowlist: ["*.example.com", "example.com"],
      // allowedHostnames: ["localhost"],
    },
    // cdpUrl: "http://127.0.0.1:18792", // 舊版單一 profile 覆寫
    remoteCdpTimeoutMs: 1500, // 遠端 CDP HTTP 逾時（毫秒）
    remoteCdpHandshakeTimeoutMs: 3000, // 遠端 CDP WebSocket 握手逾時（毫秒）
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

- 瀏覽器控制服務綁定至 loopback，埠號從 `gateway.port` 衍生（預設：`18791`，即 gateway + 2）。Relay 使用下一個埠（`18792`）。
- 若覆寫 Gateway 埠（`gateway.port` 或 `OPENCLAW_GATEWAY_PORT`），衍生的瀏覽器埠也會移動，保持在同一「系列」。
- 未設定時，`cdpUrl` 預設為 relay 埠。
- `remoteCdpTimeoutMs` 適用於遠端（非 loopback）CDP 可達性檢查。
- `remoteCdpHandshakeTimeoutMs` 適用於遠端 CDP WebSocket 可達性檢查。
- 瀏覽器導航/開啟分頁在導航前受 SSRF 保護，並在最終 `http(s)` URL 導航後盡力再次檢查。
- `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork` 預設為 `true`（信任網路模式）。設為 `false` 可進行嚴格的僅公開網路瀏覽。
- `browser.ssrfPolicy.allowPrivateNetwork` 作為舊版別名仍受支援以保持相容性。
- `attachOnly: true` 表示「永不啟動本地瀏覽器；只在已執行時才附加。」
- `color` 和每個 profile 的 `color` 為瀏覽器 UI 上色，讓你能看出哪個 profile 正在使用。
- 預設 profile 是 `openclaw`（OpenClaw 管理的獨立瀏覽器）。使用 `defaultProfile: "chrome"` 可切換至 Chrome extension relay。
- 自動偵測順序：若系統預設瀏覽器是 Chromium 系列則使用；否則 Chrome → Brave → Edge → Chromium → Chrome Canary。
- 本地 `openclaw` profiles 自動分配 `cdpPort`/`cdpUrl`——僅在遠端 CDP 時設定這些。

## 使用 Brave（或其他 Chromium 系瀏覽器）

若你的**系統預設**瀏覽器是 Chromium 系列（Chrome/Brave/Edge 等），OpenClaw 會自動使用它。設定 `browser.executablePath` 可覆寫自動偵測：

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

## 本地與遠端控制

- **本地控制（預設）：** Gateway 啟動 loopback 控制服務，並可啟動本地瀏覽器。
- **遠端控制（節點主機）：** 在有瀏覽器的機器上執行節點主機；Gateway 代理瀏覽器動作至它。
- **遠端 CDP：** 設定 `browser.profiles.<name>.cdpUrl`（或 `browser.cdpUrl`）以附加至遠端 Chromium 系瀏覽器。此情況下，OpenClaw 不會啟動本地瀏覽器。

遠端 CDP URL 可包含驗證：

- Query tokens（例如 `https://provider.example?token=<token>`）
- HTTP Basic auth（例如 `https://user:pass@provider.example`）

OpenClaw 在呼叫 `/json/*` 端點和連接 CDP WebSocket 時保留驗證。優先使用環境變數或 secrets manager 存放 token，而非寫入設定檔。

## 節點瀏覽器代理（零設定預設）

若你在有瀏覽器的機器上執行**節點主機**，OpenClaw 可以自動將瀏覽器工具呼叫路由至該節點，無需額外瀏覽器設定。這是遠端 gateway 的預設路徑。

注意：

- 節點主機透過**代理命令**公開其本地瀏覽器控制伺服器。
- Profiles 來自節點自身的 `browser.profiles` 設定（與本地相同）。
- 若不需要可停用：
  - 在節點上：`nodeHost.browserProxy.enabled=false`
  - 在 gateway 上：`gateway.nodes.browser.mode="off"`

## Browserless（託管遠端 CDP）

[Browserless](https://browserless.io) 是一個透過 HTTPS 公開 CDP 端點的託管 Chromium 服務。你可以將 OpenClaw 瀏覽器 profile 指向 Browserless 地區端點，並以你的 API key 驗證。

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

- 將 `<BROWSERLESS_API_KEY>` 替換為你實際的 Browserless token。
- 選擇符合你 Browserless 帳戶的地區端點（見其文件）。

## 直接 WebSocket CDP 提供商

某些託管瀏覽器服務公開**直接 WebSocket** 端點，而非標準的 HTTP 式 CDP 探索（`/json/version`）。OpenClaw 兩者都支援：

- **HTTP(S) 端點**（例如 Browserless）——OpenClaw 呼叫 `/json/version` 探索 WebSocket debugger URL，然後連接。
- **WebSocket 端點**（`ws://` / `wss://`）——OpenClaw 直接連接，跳過 `/json/version`。對提供 WebSocket URL 的服務（如 [Browserbase](https://www.browserbase.com)）使用此方式。

### Browserbase

[Browserbase](https://www.browserbase.com) 是一個雲端平台，用於執行內建 CAPTCHA 解決、隱身模式和住宅代理的 headless 瀏覽器。

```json5
{
  browser: {
    enabled: true,
    defaultProfile: "browserbase",
    remoteCdpTimeoutMs: 3000,
    remoteCdpHandshakeTimeoutMs: 5000,
    profiles: {
      browserbase: {
        cdpUrl: "wss://connect.browserbase.com?apiKey=<BROWSERBASE_API_KEY>",
        color: "#F97316",
      },
    },
  },
}
```

注意：

- [註冊](https://www.browserbase.com/sign-up)並從 [Overview dashboard](https://www.browserbase.com/overview) 複製你的 **API Key**。
- 將 `<BROWSERBASE_API_KEY>` 替換為你實際的 Browserbase API key。
- Browserbase 在 WebSocket 連接時自動建立瀏覽器 session，無需手動建立 session。
- 免費方案允許一個並發 session 和每月一小時的瀏覽器使用。見[定價](https://www.browserbase.com/pricing)瞭解付費方案限制。
- 完整 API 參考、SDK 指南和整合範例見 [Browserbase 文件](https://docs.browserbase.com)。

## 安全性

關鍵概念：

- 瀏覽器控制僅限 loopback；存取透過 Gateway 的驗證或節點配對流通。
- 若瀏覽器控制已啟用但未設定驗證，OpenClaw 在啟動時自動產生 `gateway.auth.token` 並持久化至設定。
- 將 Gateway 和任何節點主機保持在私人網路（Tailscale）；避免公開暴露。
- 將遠端 CDP URL/token 視為機密；優先使用環境變數或 secrets manager。

遠端 CDP 提示：

- 盡可能優先使用加密端點（HTTPS 或 WSS）和短期 token。
- 避免將長期 token 直接嵌入設定檔。

## Profiles（多瀏覽器）

OpenClaw 支援多個具名 profiles（路由設定）。Profiles 可以是：

- **openclaw 管理**：具有自己的使用者資料目錄和 CDP 埠的專屬 Chromium 系瀏覽器實例
- **遠端**：明確的 CDP URL（在其他地方執行的 Chromium 系瀏覽器）
- **Extension relay**：透過本地 relay 和 Chrome extension 控制你現有的 Chrome 分頁

預設：

- 若遺失，`openclaw` profile 會自動建立。
- `chrome` profile 內建用於 Chrome extension relay（預設指向 `http://127.0.0.1:18792`）。
- 本地 CDP 埠預設從 **18800–18899** 分配。
- 刪除 profile 會將其本地資料目錄移至垃圾桶。

所有控制端點接受 `?profile=<name>`；CLI 使用 `--browser-profile`。

## Chrome extension relay（使用你現有的 Chrome）

OpenClaw 也可以透過本地 CDP relay 和 Chrome extension 驅動**你現有的 Chrome 分頁**（無需獨立的「openclaw」Chrome 實例）。

完整指南：[Chrome extension](/zh-Hant/tools/chrome-extension)

流程：

- Gateway 在本地執行（同一台機器）或節點主機在瀏覽器機器上執行。
- 本地 **relay 伺服器**在 loopback `cdpUrl` 監聽（預設：`http://127.0.0.1:18792`）。
- 你點擊分頁上的 **OpenClaw Browser Relay** extension 圖示來附加（不自動附加）。
- Agent 透過正常的 `browser` 工具，選擇正確的 profile 控制該分頁。

若 Gateway 在其他地方執行，在瀏覽器機器上執行節點主機，讓 Gateway 可以代理瀏覽器動作。

### 沙箱化 sessions

若 agent session 已沙箱化，`browser` 工具可能預設為 `target="sandbox"`（沙箱瀏覽器）。Chrome extension relay 接管需要 host 瀏覽器控制，因此：

- 以非沙箱化方式執行 session，或
- 設定 `agents.defaults.sandbox.browser.allowHostControl: true` 並在呼叫工具時使用 `target="host"`。

### 設定

1. 載入 extension（開發/解壓縮）：

```bash
openclaw browser extension install
```

- Chrome → `chrome://extensions` → 啟用「開發人員模式」
- 「載入未封裝項目」→ 選擇 `openclaw browser extension path` 顯示的目錄
- 固定 extension，然後點擊你要控制的分頁上的圖示（徽章顯示 `ON`）。

2. 使用：

- CLI：`openclaw browser --browser-profile chrome tabs`
- Agent 工具：`browser` 加 `profile="chrome"`

選用：若你想使用不同的名稱或 relay 埠，建立自己的 profile：

```bash
openclaw browser create-profile \
  --name my-chrome \
  --driver extension \
  --cdp-url http://127.0.0.1:18792 \
  --color "#00AA00"
```

注意：

- 此模式依賴 Playwright-on-CDP 進行大多數操作（截圖/快照/動作）。
- 再次點擊 extension 圖示即可分離。
- 預設將 relay 保持在 loopback 上。若 relay 必須從不同的網路命名空間可達（例如 WSL2 中的 Gateway，Windows 上的 Chrome），將 `browser.relayBindHost` 設為明確的綁定位址（如 `0.0.0.0`），同時保持周邊網路私密和已驗證。

WSL2/跨命名空間範例：

```json5
{
  browser: {
    enabled: true,
    relayBindHost: "0.0.0.0",
    defaultProfile: "chrome",
  },
}
```

## 隔離保證

- **專屬使用者資料目錄**：從不碰你的個人瀏覽器 profile。
- **專屬埠**：避免 `9222` 以防止與開發工作流程衝突。
- **確定性分頁控制**：以 `targetId` 為目標，而非「最後一個分頁」。

## 瀏覽器選擇

本地啟動時，OpenClaw 選擇第一個可用的：

1. Chrome
2. Brave
3. Edge
4. Chromium
5. Chrome Canary

你可以用 `browser.executablePath` 覆寫。

平台：

- macOS：檢查 `/Applications` 和 `~/Applications`。
- Linux：尋找 `google-chrome`、`brave`、`microsoft-edge`、`chromium` 等。
- Windows：檢查常見安裝位置。

## Control API（選用）

僅供本地整合，Gateway 公開一個小型 loopback HTTP API：

- 狀態/啟動/停止：`GET /`、`POST /start`、`POST /stop`
- 分頁：`GET /tabs`、`POST /tabs/open`、`POST /tabs/focus`、`DELETE /tabs/:targetId`
- 快照/截圖：`GET /snapshot`、`POST /screenshot`
- 動作：`POST /navigate`、`POST /act`
- Hooks：`POST /hooks/file-chooser`、`POST /hooks/dialog`
- 下載：`POST /download`、`POST /wait/download`
- 偵錯：`GET /console`、`POST /pdf`
- 偵錯：`GET /errors`、`GET /requests`、`POST /trace/start`、`POST /trace/stop`、`POST /highlight`
- 網路：`POST /response/body`
- 狀態：`GET /cookies`、`POST /cookies/set`、`POST /cookies/clear`
- 狀態：`GET /storage/:kind`、`POST /storage/:kind/set`、`POST /storage/:kind/clear`
- 設定：`POST /set/offline`、`POST /set/headers`、`POST /set/credentials`、`POST /set/geolocation`、`POST /set/media`、`POST /set/timezone`、`POST /set/locale`、`POST /set/device`

所有端點接受 `?profile=<name>`。

若已設定 gateway 驗證，瀏覽器 HTTP 路由也需要驗證：

- `Authorization: Bearer <gateway token>`
- `x-openclaw-password: <gateway password>` 或使用該密碼的 HTTP Basic auth

### Playwright 需求

部分功能（navigate/act/AI snapshot/role snapshot、元素截圖、PDF）需要 Playwright。若未安裝 Playwright，這些端點回傳清楚的 501 錯誤。ARIA 快照和基本截圖仍可用於 openclaw 管理的 Chrome。對於 Chrome extension relay driver，ARIA 快照和截圖需要 Playwright。

若看到 `Playwright is not available in this gateway build`，安裝完整的 Playwright 套件（非 `playwright-core`）並重啟 gateway，或重新安裝帶有瀏覽器支援的 OpenClaw。

#### Docker Playwright 安裝

若你的 Gateway 在 Docker 中執行，避免使用 `npx playwright`（npm 覆寫衝突）。改用內建 CLI：

```bash
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

若要持久化瀏覽器下載，設定 `PLAYWRIGHT_BROWSERS_PATH`（例如 `/home/node/.cache/ms-playwright`），並確保 `/home/node` 透過 `OPENCLAW_HOME_VOLUME` 或 bind mount 持久化。見 [Docker](/zh-Hant/install/docker)。

## 運作原理（內部）

高層次流程：

- 一個小型**控制伺服器**接受 HTTP 請求。
- 它透過 **CDP** 連接至 Chromium 系瀏覽器（Chrome/Brave/Edge/Chromium）。
- 對於進階動作（點擊/輸入/快照/PDF），它在 CDP 之上使用 **Playwright**。
- 若缺少 Playwright，只有非 Playwright 操作可用。

此設計讓 agent 保持在穩定、確定性的介面上，同時允許你切換本地/遠端瀏覽器和 profiles。

## CLI 快速參考

所有命令接受 `--browser-profile <name>` 以指定特定 profile。
所有命令也接受 `--json` 輸出機器可讀格式（穩定的 payload）。

基本操作：

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
- `openclaw browser download e12 report.pdf`
- `openclaw browser waitfordownload report.pdf`
- `openclaw browser upload /tmp/openclaw/uploads/file.pdf`
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
- `openclaw browser set headers --headers-json '{"X-Debug":"1"}'`
- `openclaw browser set credentials user pass`
- `openclaw browser set credentials --clear`
- `openclaw browser set geo 37.7749 -122.4194 --origin "https://example.com"`
- `openclaw browser set geo --clear`
- `openclaw browser set media dark`
- `openclaw browser set timezone America/New_York`
- `openclaw browser set locale en-US`
- `openclaw browser set device "iPhone 14"`

注意：

- `upload` 和 `dialog` 是**預備**呼叫；在觸發選擇器/對話的點擊/按鍵之前執行它們。
- 下載和 trace 輸出路徑受限於 OpenClaw 臨時根目錄：
  - traces：`/tmp/openclaw`（備用：`${os.tmpdir()}/openclaw`）
  - downloads：`/tmp/openclaw/downloads`（備用：`${os.tmpdir()}/openclaw/downloads`）
- Upload 路徑受限於 OpenClaw 臨時上傳根目錄：
  - uploads：`/tmp/openclaw/uploads`（備用：`${os.tmpdir()}/openclaw/uploads`）
- `upload` 也可透過 `--input-ref` 或 `--element` 直接設定 file inputs。
- `snapshot`：
  - `--format ai`（安裝 Playwright 時的預設）：回傳帶有數字 refs 的 AI 快照（`aria-ref="<n>"`）。
  - `--format aria`：回傳無障礙樹（無 refs；僅供檢查）。
  - `--efficient`（或 `--mode efficient`）：緊湊的 role 快照預設（interactive + compact + depth + 較低 maxChars）。
  - 設定預設（僅限工具/CLI）：設定 `browser.snapshotDefaults.mode: "efficient"` 可在呼叫者未傳遞模式時使用高效快照（見 [Gateway configuration](/zh-Hant/gateway/configuration#browser-openclaw-managed-browser)）。
  - Role 快照選項（`--interactive`、`--compact`、`--depth`、`--selector`）強制基於 role 的快照，refs 格式如 `ref=e12`。
  - `--frame "<iframe selector>"` 將 role 快照範疇限制在 iframe（與 role refs 如 `e12` 配對）。
  - `--interactive` 輸出互動元素的扁平易選清單（最適合驅動動作）。
  - `--labels` 新增帶有疊加 ref 標籤的純視窗截圖（列印 `MEDIA:<path>`）。
- `click`/`type` 等需要來自 `snapshot` 的 `ref`（數字 `12` 或 role ref `e12`）。CSS 選擇器刻意不支援於動作中。

## 快照和 refs

OpenClaw 支援兩種「快照」樣式：

- **AI snapshot（數字 refs）**：`openclaw browser snapshot`（預設；`--format ai`）
  - 輸出：包含數字 refs 的文字快照。
  - 動作：`openclaw browser click 12`、`openclaw browser type 23 "hello"`。
  - 內部透過 Playwright 的 `aria-ref` 解析 ref。

- **Role snapshot（role refs 如 `e12`）**：`openclaw browser snapshot --interactive`（或 `--compact`、`--depth`、`--selector`、`--frame`）
  - 輸出：帶有 `[ref=e12]`（和選用 `[nth=1]`）的基於 role 的清單/樹。
  - 動作：`openclaw browser click e12`、`openclaw browser highlight e12`。
  - 內部透過 `getByRole(...)`（加上重複項目的 `nth()`）解析 ref。
  - 新增 `--labels` 以包含帶有疊加 `e12` 標籤的視窗截圖。

Ref 行為：

- Refs **在導航後不穩定**；若發生失敗，重新執行 `snapshot` 並使用新的 ref。
- 若 role 快照是以 `--frame` 拍攝的，role refs 範疇限於該 iframe，直到下一次 role 快照。

## Wait 增強功能

你可以等待的不僅是時間/文字：

- 等待 URL（Playwright 支援 globs）：
  - `openclaw browser wait --url "**/dash"`
- 等待載入狀態：
  - `openclaw browser wait --load networkidle`
- 等待 JS 謂詞：
  - `openclaw browser wait --fn "window.ready===true"`
- 等待選擇器變為可見：
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

當動作失敗時（例如「not visible」、「strict mode violation」、「covered」）：

1. `openclaw browser snapshot --interactive`
2. 使用 `click <ref>` / `type <ref>`（互動模式優先使用 role refs）
3. 若仍然失敗：`openclaw browser highlight <ref>` 查看 Playwright 的目標
4. 若頁面行為異常：
   - `openclaw browser errors --clear`
   - `openclaw browser requests --filter api --clear`
5. 深度偵錯：錄製 trace：
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

JSON 格式的 role 快照包含 `refs` 和小型 `stats` 區塊（lines/chars/refs/interactive），讓工具能夠推理 payload 大小和密度。

## 狀態和環境設定

這些適用於「讓網站表現得像 X」的工作流程：

- Cookies：`cookies`、`cookies set`、`cookies clear`
- Storage：`storage local|session get|set|clear`
- 離線：`set offline on|off`
- Headers：`set headers --headers-json '{"X-Debug":"1"}'`（舊版 `set headers --json '{"X-Debug":"1"}'` 仍受支援）
- HTTP basic auth：`set credentials user pass`（或 `--clear`）
- 地理位置：`set geo <lat> <lon> --origin "https://example.com"`（或 `--clear`）
- 媒體：`set media dark|light|no-preference|none`
- 時區/語系：`set timezone ...`、`set locale ...`
- 裝置/視窗：
  - `set device "iPhone 14"`（Playwright 裝置預設）
  - `set viewport 1280 720`

## 安全性與隱私

- openclaw 瀏覽器 profile 可能包含已登入的 sessions；將其視為敏感資料。
- `browser act kind=evaluate` / `openclaw browser evaluate` 和 `wait --fn` 在頁面 context 中執行任意 JavaScript。Prompt injection 可以引導這個行為。若不需要，以 `browser.evaluateEnabled=false` 停用。
- 關於登入和防機器人注意事項（X/Twitter 等），見 [Browser login + X/Twitter posting](/zh-Hant/tools/browser-login)。
- 保持 Gateway/節點主機私密（loopback 或 tailnet 專用）。
- 遠端 CDP 端點功能強大；用隧道保護它們。

嚴格模式範例（預設封鎖私人/內部目的地）：

```json5
{
  browser: {
    ssrfPolicy: {
      dangerouslyAllowPrivateNetwork: false,
      hostnameAllowlist: ["*.example.com", "example.com"],
      allowedHostnames: ["localhost"], // 選用精確允許
    },
  },
}
```

## 疑難排解

關於 Linux 特定問題（尤其是 snap Chromium），見 [Browser troubleshooting](/zh-Hant/tools/browser-linux-troubleshooting)。

關於 WSL2 Gateway + Windows Chrome 分離主機設定，見 [WSL2 + Windows + remote Chrome CDP troubleshooting](/zh-Hant/tools/browser-wsl2-windows-remote-cdp-troubleshooting)。

## Agent 工具 + 控制運作方式

Agent 獲得**一個工具**用於瀏覽器自動化：

- `browser` — status/start/stop/tabs/open/focus/close/snapshot/screenshot/navigate/act

對映關係：

- `browser snapshot` 回傳穩定的 UI 樹（AI 或 ARIA）。
- `browser act` 使用快照的 `ref` IDs 進行點擊/輸入/拖曳/選取。
- `browser screenshot` 擷取像素（全頁或元素）。
- `browser` 接受：
  - `profile` 選擇具名的瀏覽器 profile（openclaw、chrome 或遠端 CDP）。
  - `target`（`sandbox` | `host` | `node`）選擇瀏覽器所在位置。
  - 在沙箱化 sessions 中，`target: "host"` 需要 `agents.defaults.sandbox.browser.allowHostControl=true`。
  - 若省略 `target`：沙箱化 sessions 預設為 `sandbox`，非沙箱化 sessions 預設為 `host`。
  - 若已連接具備瀏覽器能力的節點，工具可能自動路由至它，除非你固定 `target="host"` 或 `target="node"`。

這讓 agent 保持確定性並避免脆弱的選擇器。
