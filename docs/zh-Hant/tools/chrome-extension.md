---
summary: "Chrome 延伸：讓 OpenClaw 控制你現有的 Chrome 標籤頁"
read_when:
  - 你希望代理控制現有的 Chrome 標籤頁（工具欄按鈕）
  - 你需要遠端網關加通過 Tailscale 的本地瀏覽器自動化
  - 你想瞭解瀏覽器接管的安全含義
title: "Chrome Extension（Chrome 擴充功能）"
---

# Chrome 延伸（瀏覽器中繼）

OpenClaw Chrome 延伸讓代理控制你的 **現有 Chrome 標籤頁**（你的正常 Chrome 視窗），而不是啟動單獨的 openclaw 管理的 Chrome 設定檔。

連接/分離通過 **單個 Chrome 工具欄按鈕** 發生。

## 它是什麼（概念）

有三個部分：

- **瀏覽器控制服務**（網關或 node）：代理/工具呼叫的 API（通過網關）
- **本地中繼伺服器**（環回 CDP）：在控制伺服器和延伸（`http://127.0.0.1:18792` 預設）之間橋接
- **Chrome MV3 延伸**：使用 `chrome.debugger` 連接到活躍標籤頁並將 CDP 訊息傳遞到中繼

OpenClaw 然後通過正常的 `browser` 工具表面控制連接的標籤頁（選擇正確的設定檔）。

## 安裝 / 加載（未打包）

1. 將延伸安裝到穩定的本地路徑：

```bash
openclaw browser extension install
```

2. 列印已安裝的延伸目錄路徑：

```bash
openclaw browser extension path
```

3. Chrome → `chrome://extensions`

- 啟用「開發者模式」
- 「加載未打包的延伸」→ 選擇上面列印的目錄

4. 釘住延伸。

## 更新（無構建步驟）

延伸作為靜態檔案在 OpenClaw 版本（npm 套件）內發送。沒有單獨的「構建」步驟。

升級 OpenClaw 後：

- 重新執行 `openclaw browser extension install` 以刷新 OpenClaw 狀態目錄下已安裝的檔案。
- Chrome → `chrome://extensions` → 在延伸上點擊「重新加載」。

## 使用它（設定網關 token 一次）

OpenClaw 配備名為 `chrome` 的內建瀏覽器檔案，目標延伸中繼在預設埠。

首次連接前，開啟延伸選項並設定：

- `Port`（預設 `18792`）
- `Gateway token`（必須與 `gateway.auth.token` / `OPENCLAW_GATEWAY_TOKEN` 相符）

使用它：

- CLI：`openclaw browser --browser-profile chrome tabs`
- 代理工具：`browser`，帶 `profile="chrome"`

如果你想要不同的名稱或不同的中繼埠，建立你自己的檔案：

```bash
openclaw browser create-profile \
  --name my-chrome \
  --driver extension \
  --cdp-url http://127.0.0.1:18792 \
  --color "#00AA00"
```

### 自訂網關埠

如果你使用自訂網關埠，延伸中繼埠自動衍生：

**延伸中繼埠 = 網關埠 + 3**

範例：如果 `gateway.port: 19001`，然後：

- 延伸中繼埠：`19004`（網關 + 3）

在延伸選項頁面配置延伸使用衍生的中繼埠。

## 連接 / 分離（工具欄按鈕）

- 開啟你希望 OpenClaw 控制的標籤頁。
- 點擊延伸圖示。
  - 徽章在連接時顯示 `ON`。
- 再次點擊以分離。

## 它控制哪個標籤頁？

- 它 **不會** 自動控制「無論你正在看什麼標籤頁」。
- 它控制 **僅你明確通過點擊工具欄按鈕連接的標籤頁**。
- 切換：開啟其他標籤頁並在那裡點擊延伸圖示。

## 徽章加常見錯誤

- `ON`：已連接；OpenClaw 可以控制該標籤頁。
- `…`：正在連接到本地中繼。
- `!`：中繼不可達/未認證（最常見：中繼伺服器未執行或網關 token 遺失/錯誤）。

如果你看到 `!`：

- 確保網關本地執行（預設設定），或如果網關在別處執行，在此機器上執行 node 主機。
- 開啟延伸選項頁面；它驗證中繼可達性加網關-token 認證。

## 遠端網關（使用 node 主機）

### 本地網關（與 Chrome 相同的機器） — 通常 **無額外步驟**

如果網關在 Chrome 相同的機器上執行，它在環回上啟動瀏覽器控制服務
並自動啟動中繼伺服器。延伸與本地中繼交談；CLI/工具呼叫走向網關。

### 遠端網關（網關在別處執行） — **執行 node 主機**

如果你的網關在另一台機器上執行，在執行 Chrome 的機器上啟動 node 主機。
網關將代理瀏覽器操作到該 node；延伸加中繼保持本地到瀏覽器機器。

如果連接多個 node，用 `gateway.nodes.browser.node` 釘住一個或設定 `gateway.nodes.browser.mode`。

## 沙盒化（工具容器）

如果你的代理會話被沙盒化（`agents.defaults.sandbox.mode != "off"`），`browser` 工具可以受限：

- 預設情況下，沙盒化會話通常目標 **沙盒瀏覽器**（`target="sandbox"`），不是你的主機 Chrome。
- Chrome 延伸中繼接管需要控制 **主機** 瀏覽器控制伺服器。

選項：

- 最簡單：使用來自 **非沙盒化** 會話/代理的延伸。
- 或允許沙盒化會話的主機瀏覽器控制：

```json5
{
  agents: {
    defaults: {
      sandbox: {
        browser: {
          allowHostControl: true,
        },
      },
    },
  },
}
```

然後確保工具未被工具原則拒絕，並（如果需要）用 `target="host"` 呼叫 `browser`。

調試：`openclaw sandbox explain`

## 遠端存取提示

- 保持網關和 node 主機在相同 tailnet；避免向 LAN 或公眾網際網路暴露中繼埠。
- 故意配對 node；如果你不想要遠端控制，禁用瀏覽器代理路由（`gateway.nodes.browser.mode="off"`）。

## 「延伸路徑」如何運作

`openclaw browser extension path` 列印 **已安裝** 的磁碟目錄，包含延伸檔案。

CLI 故意 **不** 列印 `node_modules` 路徑。總是首先執行 `openclaw browser extension install` 以將延伸複製到 OpenClaw 狀態目錄下的穩定位置。

如果你移動或刪除該安裝目錄，Chrome 將標記延伸為破損，直到你從有效路徑重新加載它。

## 安全含義（閱讀這個）

這是強大且風險大的。將其視為給予模型「手在你的瀏覽器上」。

- 延伸使用 Chrome 的偵錯器 API（`chrome.debugger`）。連接時，模型可以：
  - 在該標籤頁中點擊/類型/導航
  - 讀取頁面內容
  - 存取無論該標籤頁登入會話可以存取什麼
- **這不是隔離的**，像專用 openclaw 管理的檔案。
  - 如果你連接到你的日常驅動程式檔案/標籤頁，你正在授予對該帳戶狀態的存取。

建議：

- 傾向於專用 Chrome 檔案（獨立於你的個人瀏覽）用於延伸中繼使用。
- 保持網關和任何 node 主機 tailnet 僅；依賴網關認證加 node 配對。
- 避免通過 LAN 暴露中繼埠（`0.0.0.0`）並避免 Funnel（公眾）。
- 中繼阻止非延伸起源並為 `/cdp` 和 `/extension` 都需要網關-token 認證。

相關：

- 瀏覽器工具概述：[瀏覽器](/zh-Hant/tools/browser)
- 安全稽核：[安全](/zh-Hant/gateway/security)
- Tailscale 設定：[Tailscale](/zh-Hant/gateway/tailscale)
