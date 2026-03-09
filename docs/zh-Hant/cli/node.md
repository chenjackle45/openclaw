---
summary: "`openclaw node` CLI 參考（無頭節點主機）"
read_when:
  - 運行無頭節點主機時
  - 為非 macOS 裝置配對 system.run 時
title: "node（節點主機）"
---

# `openclaw node`

運行一個**無頭節點主機**，使其連接至 Gateway WebSocket 並在此機器上提供
`system.run` / `system.which`。

## 為什麼要使用節點主機？

當您希望 Agent 在網路中的**其他機器上執行指令**，而不需在該機器上安裝完整的 macOS 隨附應用程式時，請使用節點主機。

常見情境：

- 在遠端 Linux/Windows 機器（編譯伺服器、實驗室機器、NAS）上執行指令。
- 讓執行過程在 gateway 上保持**沙盒化**，但將經核准的執行委派給其他主機。
- 為自動化流程或 CI 節點提供輕量級、無頭的執行目標。

執行仍受節點主機上的**執行核准**和 per-agent 允許清單保護，因此您可以嚴格控管指令存取範圍。

## 瀏覽器代理（零配置）

若節點上的 `browser.enabled` 未停用，節點主機會自動廣播瀏覽器代理。這讓 agent 可以在該節點上使用瀏覽器自動化，無需額外配置。

若有需要，可在節點上停用：

```json5
{
  nodeHost: {
    browserProxy: {
      enabled: false,
    },
  },
}
```

## 執行（前景）

```bash
openclaw node run --host <gateway-host> --port 18789
```

選項：

- `--host <host>`：Gateway WebSocket 主機（預設：`127.0.0.1`）
- `--port <port>`：Gateway WebSocket 連接埠（預設：`18789`）
- `--tls`：連線 gateway 時使用 TLS
- `--tls-fingerprint <sha256>`：預期的 TLS 憑證指紋（sha256）
- `--node-id <id>`：覆寫節點 ID（清除配對 token）
- `--display-name <name>`：覆寫節點顯示名稱

## 節點主機的 Gateway 認證

`openclaw node run` 和 `openclaw node install` 從 config/env 解析 gateway 認證（node 指令沒有 `--token`/`--password` 旗標）：

- 首先檢查 `OPENCLAW_GATEWAY_TOKEN` / `OPENCLAW_GATEWAY_PASSWORD`。
- 然後本地 config 回退：`gateway.auth.token` / `gateway.auth.password`。
- 在本地模式下，當 `gateway.auth.*` 未設定時，`gateway.remote.token` / `gateway.remote.password` 也可作為回退。
- 在 `gateway.mode=remote` 下，遠端客戶端欄位（`gateway.remote.token` / `gateway.remote.password`）也依遠端優先規則符合條件。
- 傳統的 `CLAWDBOT_GATEWAY_*` env vars 在節點主機認證解析中被忽略。

## 服務（背景）

將無頭節點主機安裝為使用者服務。

```bash
openclaw node install --host <gateway-host> --port 18789
```

選項：

- `--host <host>`：Gateway WebSocket 主機（預設：`127.0.0.1`）
- `--port <port>`：Gateway WebSocket 連接埠（預設：`18789`）
- `--tls`：連線 gateway 時使用 TLS
- `--tls-fingerprint <sha256>`：預期的 TLS 憑證指紋（sha256）
- `--node-id <id>`：覆寫節點 ID（清除配對 token）
- `--display-name <name>`：覆寫節點顯示名稱
- `--runtime <runtime>`：服務執行環境（`node` 或 `bun`）
- `--force`：若已安裝則重新安裝/覆寫

管理服務：

```bash
openclaw node status
openclaw node stop
openclaw node restart
openclaw node uninstall
```

使用 `openclaw node run` 執行前景節點主機（無服務）。

服務指令接受 `--json` 以供機器可讀輸出。

## 配對

首次連線時會在 Gateway 上建立一個待處理的裝置配對請求（`role: node`）。
透過以下方式核准：

```bash
openclaw devices list
openclaw devices approve <requestId>
```

節點主機將其節點 ID、token、顯示名稱及 gateway 連線資訊儲存於
`~/.openclaw/node.json`。

## 執行核准

`system.run` 受本地執行核准限制：

- `~/.openclaw/exec-approvals.json`
- [Exec approvals](/zh-Hant/tools/exec-approvals)
- `openclaw approvals --node <id|name|ip>`（從 Gateway 端編輯）
