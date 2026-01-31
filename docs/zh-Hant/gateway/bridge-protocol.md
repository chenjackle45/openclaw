---
title: "bridge-protocol(Bridge Protocol)"
summary: "Bridge protocol (legacy nodes): TCP JSONL, pairing, scoped RPC"
read_when:
  - 建置或除錯 Node Users (iOS/Android/macOS node mode)
  - 調查配對或 Bridge Auth 失敗時
  - 稽核 Gateway 暴露的 Node Surface 時
---

# Bridge Protocol (Legacy Node Transport)

Bridge Protocol 是一個 **舊版 (Legacy)** Node 傳輸協定 (TCP JSONL)。新的 Node Clients 應使用統一的 Gateway WebSocket 協定。

若您正在建置 Operator 或 Node Client，請使用 [Gateway protocol](/gateway/protocol)。

**注意:** 目前的 OpenClaw 建置不再隨附 TCP Bridge Listener；此文件保留作為歷史參考。舊版 `bridge.*` 設定鍵已不再是 Config Schema 的一部分。

## 為何我們兩者都有

- **安全性邊界**: Bridge 暴露小型 Allowlist 而非完整的 Gateway API Surface。
- **配對 + Node 身分**: Node 准入由 Gateway 擁有並綁定至 Per-node Token。
- **Discovery UX**: Nodes 可透過 LAN 上的 Bonjour 發現 Gateways，或透過 Tailnet 直接連線。
- **Loopback WS**: 完整 WS 控制平面保持本地，除非透過 SSH Tunnel。

## 傳輸

- TCP, 每行一個 JSON 物件 (JSONL)。
- 選用的 TLS (當 `bridge.tls.enabled` 為真時)。
- 舊版預設 Listener Port 為 `18790` (目前建置不啟動 TCP Bridge)。

當 TLS 啟用時，Discovery TXT 記錄包含 `bridgeTls=1` 加上 `bridgeTlsSha256` 以便 Nodes 可釘選 (Pin) 憑證。

## 握手 + 配對

1) Client 發送 `hello` 帶有 Node Metadata + Token (若已配對)。
2) 若未配對，Gateway 回覆 `error` (`NOT_PAIRED`/`UNAUTHORIZED`)。
3) Client 發送 `pair-request`。
4) Gateway 等待核准，然後發送 `pair-ok` 與 `hello-ok`。

`hello-ok` 回傳 `serverName` 並可能包含 `canvasHostUrl`。

## Frames

Client → Gateway:
- `req` / `res`: Scoped Gateway RPC (chat, sessions, config, health, voicewake, skills.bins)
- `event`: Node Signals (voice transcript, agent request, chat subscribe, exec lifecycle)

Gateway → Client:
- `invoke` / `invoke-res`: Node Commands (`canvas.*`, `camera.*`, `screen.record`, `location.get`, `sms.send`)
- `event`: 已訂閱 Session 的聊天更新
- `ping` / `pong`: Keepalive

舊版 Allowlist 強制執行位於 `src/gateway/server-bridge.ts` (已移除)。

## Exec Lifecycle Events

Nodes 可發出 `exec.finished` 或 `exec.denied` 事件以呈現 `system.run` 活動。這些被映射至 Gateway 中的系統事件。(舊版 Nodes 可能仍發出 `exec.started`。)

Payload 欄位 (除非註明否則為選填):
- `sessionKey` (必填): 接收系統事件的 Agent Session。
- `runId`: 用於分組的 Unique Exec ID。
- `command`: 原始或格式化的指令字串。
- `exitCode`, `timedOut`, `success`, `output`: 完成詳細資訊 (僅限 Finished)。
- `reason`: 拒絕原因 (僅限 Denied)。

## Tailnet 用法

- 在 `~/.openclaw/openclaw.json` 中將 Bridge 綁定至 Tailnet IP: `bridge.bind: "tailnet"`。
- Clients 透過 MagicDNS 名稱或 Tailnet IP 連線。
- Bonjour **不** 跨越網路；需要時使用手動 Host/Port 或廣域 DNS‑SD。

## 版本控制 (Versioning)

Bridge 目前為 **Implicit v1** (無 Min/Max 協商)。預期向下相容；在任何破壞性變更前新增 Bridge Protocol Version 欄位。
