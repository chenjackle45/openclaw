---
title: "Typebox(TypeBox Schemas)"
summary: "TypeBox 架構作為 Gateway 通訊協議的單一事實來源"
read_when:
  - 更新協議架構或程式碼生成 (codegen)
---
# TypeBox as protocol source of truth（TypeBox 作為協議事實來源）

最後更新：2026-01-10

TypeBox 是一個 TypeScript 優先的架構庫。我們使用它來定義 **Gateway WebSocket 協議**（握手、請求/回應、伺服器事件）。這些架構驅動著**運行時驗證**、**JSON Schema 匯出**以及 macOS 應用程式的 **Swift 程式碼生成**。單一事實來源，其餘一切均由其生成。

如果您需要更高層級的協議背景，請先閱讀 [Gateway architecture（Gateway 架構）](/concepts/architecture)。

## 心理模型（30 秒）

每個 Gateway WS 訊息都是以下三種框架 (frames) 之一：

- **Request (請求)**：`{ type: "req", id, method, params }`
- **Response (回應)**：`{ type: "res", id, ok, payload | error }`
- **Event (事件)**：`{ type: "event", event, payload, seq?, stateVersion? }`

第一個框架**必須**是 `connect` 請求。在此之後，客戶端可以呼叫各種方法（例如 `health`, `send`, `chat.send`）並訂閱事件（例如 `presence`, `tick`, `agent`）。

連接流程（極簡版）：

```
Client                    Gateway
  |---- req:connect -------->|
  |<---- res:hello-ok --------|
  |<---- event:tick ----------|
  |---- req:health ---------->|
  |<---- res:health ----------|
```

事實清單位於 `src/gateway/server.ts` (`METHODS`, `EVENTS`)。

## 架構存放位置

- 原始碼：`src/gateway/protocol/schema.ts`
- 執行時驗證器 (AJV)：`src/gateway/protocol/index.ts`
- 伺服器握手 + 方法派遣：`src/gateway/server.ts`
- Node 客戶端：`src/gateway/client.ts`
- 生成的 JSON Schema：`dist/protocol.schema.json`
- 生成的 Swift 模型：`apps/macos/Sources/OpenClawProtocol/GatewayModels.swift`

## 目前管線 (Pipeline)

- `pnpm protocol:gen`
  - 將 JSON Schema (draft‑07) 寫入 `dist/protocol.schema.json`
- `pnpm protocol:gen:swift`
  - 生成 Swift Gateway 模型
- `pnpm protocol:check`
  - 執行上述兩個生成器，並驗證導出內容是否已提交

## 架構在執行時如何被使用

- **伺服器端**：每個傳入的框架都使用 AJV 進行驗證。握手僅接受參數符合 `ConnectParams` 的 `connect` 請求。
- **客戶端**：JS 客戶端在接收事件和回傳回框架前會進行驗證。

## 極簡客戶端範例 (Node.js)

最簡單且有用的流程：連接 + 健康檢查 (health)。

```ts
import { WebSocket } from "ws";

const ws = new WebSocket("ws://127.0.0.1:18789");

ws.on("open", () => {
  ws.send(JSON.stringify({
    type: "req",
    id: "c1",
    method: "connect",
    params: {
      minProtocol: 3,
      maxProtocol: 3,
      client: {
        id: "cli",
        displayName: "example",
        version: "dev",
        platform: "node",
        mode: "cli"
      }
    }
  }));
});

ws.on("message", (data) => {
  const msg = JSON.parse(String(data));
  if (msg.type === "res" && msg.id === "c1" && msg.ok) {
    ws.send(JSON.stringify({ type: "req", id: "h1", method: "health" }));
  }
  if (msg.type === "res" && msg.id === "h1") {
    console.log("health:", msg.payload);
    ws.close();
  }
});
```

## Swift Codegen 行為

Swift 生成器會導出：

- `GatewayFrame` 列舉 (enum)，包含 `req`, `res`, `event` 和 `unknown` 情形
- 強型別的負載結構體 (structs)/列舉
- `ErrorCode` 值與 `GATEWAY_PROTOCOL_VERSION`

為了向前相容，未知的框架類型會被保留為原始負載。

## 更改架構時

1. 更新 TypeBox 架構。
2. 執行 `pnpm protocol:check`。
3. 提交重新生成的架構與 Swift 模型。
