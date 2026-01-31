---
title: "node(節點主機)"
summary: "`openclaw node` CLI 參考（無頭節點主機）"
read_when:
  - 運行無頭 (Headless) 節點主機時
  - 為非 macOS 裝置進行 system.run 配對時
---

# `openclaw node`

運行一個**無頭 (Headless) 節點主機**，使其連接至 Gateway 的 WebSocket，並在該機器上提供 `system.run` 與 `system.which` 的能力。

## 為什麼要使用節點主機？

當您希望 Agent 在網路中的**其它機器上執行指令**，但又不希望在該機器上安裝完整的 macOS 隨附應用程式時，請使用節點主機。

常見情境：
- 在遠端的 Linux/Windows 機器（編譯伺服器、實驗室機器、NAS）上執行指令。
- 讓執行過程在 Gateway 上保持**沙盒化**，但將經過核准的任務委派給其它主機執行。
- 為自動化流程或 CI 節點提供輕量級、無介面的執行目標。

所有執行動作仍受節點主機上的**執行核准 (Exec Approvals)** 機制與 Agent 允許清單保護，因此您可以嚴格控管指令的存取權限。

## 瀏覽器代理 (零設定)

若節點上未停用 `browser.enabled`，節點主機會自動宣告瀏覽器代理 (Browser Proxy)。這讓 Agent 可以直接在該節點上使用瀏覽器自動化功能，無需額外設定。

若有需要，可在節點配置中停用：

```json5
{
  nodeHost: {
    browserProxy: {
      enabled: false
    }
  }
}
```

## 運行 (前景模式)

```bash
openclaw node run --host <gateway主機位址> --port 18789
```

**參數選項**：
- `--host <host>`：Gateway WebSocket 主機（預設：`127.0.0.1`）。
- `--port <port>`：Gateway WebSocket 埠位（預設：`18789`）。
- `--tls`：連線至 Gateway 時使用 TLS。
- `--tls-fingerprint <sha256>`：預期的 TLS 憑證指紋。
- `--node-id <id>`：覆寫節點 ID。
- `--display-name <name>`：覆寫節點顯示名稱。

## 服務 (背景模式)

將無頭節點主機安裝為使用者服務。

```bash
openclaw node install --host <gateway主機位址> --port 18789
```

**管理服務指令**：

```bash
openclaw node status
openclaw node stop
openclaw node restart
openclaw node uninstall
```

服務指令皆支援 `--json` 格式輸出。

## 配對流程 (Pairing)

首次連線時，會在 Gateway 上建立一個待處理的節點配對請求。請透過以下指令進行核准：

```bash
# 查看待處理請求
openclaw nodes pending

# 核准配對
openclaw nodes approve <請求ID>
```

節點主機會將其 ID、權杖、顯示名稱與連線資訊儲存於 `~/.openclaw/node.json` 中。

## 執行核准 (Exec Approvals)

`system.run` 的權限由本地的執行核准機制控管：
- 修改位置：`~/.openclaw/exec-approvals.json`
- 詳細說明：[執行核准](/tools/exec-approvals)
- 遠端編輯：`openclaw approvals --node <ID|名稱|IP>` (從 Gateway 端編輯)
