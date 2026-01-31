---
title: "canvas(Canvas)"
summary: "透過 WKWebView + 自訂 URL Scheme 嵌入的 Agent 控制 Canvas 面板"
read_when:
  - 實作 macOS Canvas 面板時
  - 為視覺工作區新增 Agent 控制項時
  - Debug WKWebView Canvas 載入問題時
---

# Canvas (macOS 應用程式)

macOS 應用程式使用 `WKWebView` 嵌入了一個由 Agent 控制的 **Canvas 面板**。
它是一個輕量級的視覺工作區，適用於 HTML/CSS/JS、A2UI 以及小型互動式 UI 介面。

## Canvas 位於何處

Canvas 狀態儲存於 Application Support 下：

- `~/Library/Application Support/OpenClaw/canvas/<session>/...`

Canvas 面板透過 **自訂 URL Scheme** 提供這些檔案：

- `openclaw-canvas://<session>/<path>`

範例：
- `openclaw-canvas://main/` → `<canvasRoot>/main/index.html`
- `openclaw-canvas://main/assets/app.css` → `<canvasRoot>/main/assets/app.css`
- `openclaw-canvas://main/widgets/todo/` → `<canvasRoot>/main/widgets/todo/index.html`

若根目錄下不存在 `index.html`，應用程式會顯示 **內建的鷹架頁面 (scaffold page)**。

## 面板行為

- 無邊框、可調整大小的面板，錨定於選單列（或滑鼠游標）附近。
- 每個工作階段會記住其大小/位置。
- 當本地 Canvas 檔案變更時自動重新載入。
- 一次僅顯示一個 Canvas 面板（視需要切換工作階段）。

Canvas 可從 Settings → **Allow Canvas** 停用。停用時，Canvas 節點指令會回傳 `CANVAS_DISABLED`。

## Agent API

Canvas 透過 **Gateway WebSocket** 暴露，因此 Agent 可以：

- 顯示/隱藏面板
- 導航至路徑或 URL
- 評估 (Evaluate) JavaScript
- 擷取快照圖片

CLI 範例：

```bash
openclaw nodes canvas present --node <id>
openclaw nodes canvas navigate --node <id> --url "/"
openclaw nodes canvas eval --node <id> --js "document.title"
openclaw nodes canvas snapshot --node <id>
```

注意：
- `canvas.navigate` 接受 **本地 Canvas 路徑**、`http(s)` URL 以及 `file://` URL。
- 若傳遞 `"/"`，Canvas 會顯示本地鷹架或 `index.html`。

## Canvas 中的 A2UI

A2UI 由 Gateway Canvas Host 託管，並在 Canvas 面板內渲染。
當 Gateway 廣播 Canvas Host 時，macOS 應用程式會在首次開啟時自動導航至 A2UI Host 頁面。

預設 A2UI Host URL：

```
http://<gateway-host>:18793/__openclaw__/a2ui/
```

### A2UI 指令 (v0.8)

Canvas 目前接受 **A2UI v0.8** 伺服器→客戶端訊息：

- `beginRendering`
- `surfaceUpdate`
- `dataModelUpdate`
- `deleteSurface`

不支援 `createSurface` (v0.9)。

CLI 範例：

```bash
cat > /tmp/a2ui-v0.8.jsonl <<'EOFA2'
{"surfaceUpdate":{"surfaceId":"main","components":[{"id":"root","component":{"Column":{"children":{"explicitList":["title","content"]}}}},{"id":"title","component":{"Text":{"text":{"literalString":"Canvas (A2UI v0.8)"},"usageHint":"h1"}}},{"id":"content","component":{"Text":{"text":{"literalString":"If you can read this, A2UI push works."},"usageHint":"body"}}}]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
EOFA2

openclaw nodes canvas a2ui push --jsonl /tmp/a2ui-v0.8.jsonl --node <id>
```

快速冒煙測試：

```bash
openclaw nodes canvas a2ui push --node <id> --text "Hello from A2UI"
```

## 從 Canvas 觸發 Agent 運行

Canvas 可以透過 Deep Links 觸發新的 Agent 運行：

- `openclaw://agent?...`

範例 (JS)：

```js
window.location.href = "openclaw://agent?message=Review%20this%20design";
```

若未提供有效金鑰，應用程式會提示確認。

## 安全性注意事項

- Canvas Scheme 會阻擋目錄遍歷 (directory traversal)；檔案必須位於工作階段根目錄下。
- 本地 Canvas 內容使用自訂 Scheme（無需 loopback 伺服器）。
- 外部 `http(s)` URL 僅在明確導航時允許。
