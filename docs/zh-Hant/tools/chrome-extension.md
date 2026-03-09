---
summary: "Chrome extension：讓 OpenClaw 控制你現有的 Chrome 分頁"
read_when:
  - 你想讓 agent 控制現有的 Chrome 分頁（工具列按鈕）
  - 你需要透過 Tailscale 進行遠端 Gateway + 本地瀏覽器自動化
  - 你想了解瀏覽器接管的安全含義
title: "Chrome Extension（Chrome 擴充功能）"
---

# Chrome extension (browser relay)

OpenClaw Chrome extension 讓 agent 控制你**現有的 Chrome 分頁**（你的普通 Chrome 視窗），而非啟動獨立的 openclaw 管理 Chrome profile。

附加/分離透過**一個 Chrome 工具列按鈕**完成。

## 概念說明

有三個部分：

- **瀏覽器控制服務**（Gateway 或節點）：agent/工具呼叫的 API（透過 Gateway）
- **本地 relay 伺服器**（loopback CDP）：在控制伺服器和 extension 之間橋接（預設 `http://127.0.0.1:18792`）
- **Chrome MV3 extension**：使用 `chrome.debugger` 附加至活躍分頁，並將 CDP 訊息傳送至 relay

OpenClaw 接著透過正常的 `browser` 工具介面（選擇正確的 profile）控制已附加的分頁。

## 安裝/載入（未封裝）

1. 將 extension 安裝至穩定的本地路徑：

```bash
openclaw browser extension install
```

2. 列印已安裝的 extension 目錄路徑：

```bash
openclaw browser extension path
```

3. Chrome → `chrome://extensions`

- 啟用「開發人員模式」
- 「載入未封裝項目」→ 選擇上面列印的目錄

4. 固定 extension。

## 更新（無需建構步驟）

Extension 作為靜態檔案包含在 OpenClaw 發布版本（npm 套件）中。沒有單獨的「建構」步驟。

升級 OpenClaw 後：

- 重新執行 `openclaw browser extension install` 以重新整理 OpenClaw 狀態目錄下的已安裝檔案。
- Chrome → `chrome://extensions` → 點擊 extension 上的「重新載入」。

## 使用（一次設定 gateway token）

OpenClaw 內建一個名為 `chrome` 的瀏覽器 profile，指向預設埠上的 extension relay。

首次附加前，開啟 extension 選項並設定：

- `Port`（預設 `18792`）
- `Gateway token`（必須與 `gateway.auth.token` / `OPENCLAW_GATEWAY_TOKEN` 相符）

使用方式：

- CLI：`openclaw browser --browser-profile chrome tabs`
- Agent 工具：`browser` 加 `profile="chrome"`

若想使用不同名稱或 relay 埠，建立自己的 profile：

```bash
openclaw browser create-profile \
  --name my-chrome \
  --driver extension \
  --cdp-url http://127.0.0.1:18792 \
  --color "#00AA00"
```

### 自訂 Gateway 埠

若使用自訂 gateway 埠，extension relay 埠會自動衍生：

**Extension Relay 埠 = Gateway 埠 + 3**

範例：若 `gateway.port: 19001`，則：

- Extension relay 埠：`19004`（gateway + 3）

在 extension 選項頁面設定使用衍生的 relay 埠。

## 附加/分離（工具列按鈕）

- 開啟你想讓 OpenClaw 控制的分頁。
- 點擊 extension 圖示。
  - 附加時徽章顯示 `ON`。
- 再次點擊即可分離。

## 它控制哪個分頁？

- 它**不會**自動控制「你正在看的分頁」。
- 它只控制你透過點擊工具列按鈕**明確附加**的分頁。
- 若要切換：開啟另一個分頁，在那個分頁上點擊 extension 圖示。

## 徽章 + 常見錯誤

- `ON`：已附加；OpenClaw 可以控制該分頁。
- `…`：正在連接至本地 relay。
- `!`：relay 不可達/未驗證（最常見：relay 伺服器未執行，或 gateway token 遺失/錯誤）。

若看到 `!`：

- 確認 Gateway 在本地執行（預設設定），或若 Gateway 在其他地方執行則在此機器上執行節點主機。
- 開啟 extension 選項頁面；它會驗證 relay 可達性 + gateway-token 驗證。

## 遠端 Gateway（使用節點主機）

### 本地 Gateway（與 Chrome 同一台機器）——通常**無需額外步驟**

若 Gateway 與 Chrome 在同一台機器上執行，它會在 loopback 上啟動瀏覽器控制服務並自動啟動 relay 伺服器。Extension 與本地 relay 通訊；CLI/工具呼叫傳至 Gateway。

### 遠端 Gateway（Gateway 在其他地方執行）——**執行節點主機**

若你的 Gateway 在另一台機器上執行，在執行 Chrome 的機器上啟動節點主機。Gateway 將代理瀏覽器動作至該節點；extension 和 relay 保持在瀏覽器機器的本地。

若連接了多個節點，以 `gateway.nodes.browser.node` 固定某一個，或設定 `gateway.nodes.browser.mode`。

## 沙箱化（工具容器）

若你的 agent session 已沙箱化（`agents.defaults.sandbox.mode != "off"`），`browser` 工具可能受限：

- 預設情況下，沙箱化 sessions 通常指向**沙箱瀏覽器**（`target="sandbox"`），而非你的 host Chrome。
- Chrome extension relay 接管需要控制 **host** 瀏覽器控制伺服器。

選項：

- 最簡單：從**非沙箱化** session/agent 使用 extension。
- 或為沙箱化 sessions 允許 host 瀏覽器控制：

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

然後確認工具未被工具政策拒絕，並在需要時以 `target="host"` 呼叫 `browser`。

偵錯：`openclaw sandbox explain`

## 遠端存取提示

- 將 Gateway 和節點主機保持在同一 tailnet；避免將 relay 埠暴露至 LAN 或公共網際網路。
- 刻意配對節點；若不需要遠端控制則停用瀏覽器代理路由（`gateway.nodes.browser.mode="off"`）。
- 預設將 relay 保持在 loopback 上。對於 WSL2 或類似的分離主機設定，將 `browser.relayBindHost` 設為明確的綁定位址（如 `0.0.0.0`），然後以 Gateway 驗證、節點配對和私人網路限制存取。

## 「extension path」的運作方式

`openclaw browser extension path` 列印包含 extension 檔案的已安裝磁碟目錄。

CLI 刻意**不**列印 `node_modules` 路徑。務必先執行 `openclaw browser extension install`，將 extension 複製至 OpenClaw 狀態目錄下的穩定位置。

若你移動或刪除該安裝目錄，Chrome 會將 extension 標記為損壞，直到你從有效路徑重新載入。

## 安全含義（請閱讀）

這功能強大且有風險。將其視為給模型「操控你的瀏覽器的雙手」。

- Extension 使用 Chrome 的 debugger API（`chrome.debugger`）。附加後，模型可以：
  - 在該分頁中點擊/輸入/導航
  - 讀取頁面內容
  - 存取分頁已登入 session 可以存取的任何內容
- **這與**專屬的 openclaw 管理 profile **不同，沒有隔離**。
  - 若你附加至你的日常 profile/分頁，你就是在授予對該帳戶狀態的存取權。

建議：

- 優先使用專屬的 Chrome profile（與你的個人瀏覽不同）進行 extension relay 使用。
- 將 Gateway 和任何節點主機保持在 tailnet 專用；依賴 Gateway 驗證 + 節點配對。
- 避免在 LAN 上暴露 relay 埠（`0.0.0.0`），避免使用 Funnel（公開）。
- Relay 封鎖非 extension 來源，並要求 `/cdp` 和 `/extension` 都需要 gateway-token 驗證。

相關文件：

- 瀏覽器工具概覽：[Browser](/zh-Hant/tools/browser)
- 安全稽核：[Security](/zh-Hant/gateway/security)
- Tailscale 設定：[Tailscale](/zh-Hant/gateway/tailscale)
