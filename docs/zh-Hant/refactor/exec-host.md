---
title: "Exec host refactor(Exec host 重構計畫)"
summary: "重構計畫：exec host 路由、節點核准和 headless runner"
read_when:
  - 設計 exec host 路由或 exec 核准
  - 實作 node runner + UI IPC
  - 新增 exec host 安全模式和 slash 指令
---

# Exec host refactor plan(Exec host 重構計畫)

## 目標
- 新增 `exec.host` + `exec.security` 以在 **sandbox**、**gateway** 和 **node** 之間路由執行。
- 保持預設**安全**：除非明確啟用，否則無跨 host 執行。
- 將執行拆分為**headless runner 服務**，透過本地 IPC 具有可選 UI（macOS app）。
- 提供**每個代理**的策略、允許清單、詢問模式和節點綁定。
- 支援與允許清單*一起*或*不使用*允許清單的**詢問模式**。
- 跨平台：Unix socket + token 認證（macOS/Linux/Windows 平價）。

## 非目標
- 無舊版允許清單遷移或舊版 schema 支援。
- 節點 exec 無 PTY/串流（僅聚合輸出）。
- 超出現有 Bridge + Gateway 的新網路層。

## 決策（鎖定）
- **設定鍵：**`exec.host` + `exec.security`（允許每個代理覆蓋）。
- **提升：**保持 `/elevated` 作為 gateway 完全存取的別名。
- **預設詢問：**`on-miss`。
- **核准儲存：**`~/.openclaw/exec-approvals.json`（JSON，無舊版遷移）。
- **Runner：**headless 系統服務；UI app 託管用於核准的 Unix socket。
- **節點身份：**使用現有 `nodeId`。
- **Socket 認證：**Unix socket + token（跨平台）；需要時稍後拆分。
- **節點 host 狀態：**`~/.openclaw/node.json`（node id + 配對 token）。
- **macOS exec host：**在 macOS app 內執行 `system.run`；node host 服務透過本地 IPC 轉發請求。
- **無 XPC helper：**堅持 Unix socket + token + peer 檢查。

## 關鍵概念
### Host
- `sandbox`：Docker exec（當前行為）。
- `gateway`：在 gateway host 上執行。
- `node`：透過 Bridge 在 node runner 上執行（`system.run`）。

### 安全模式
- `deny`：始終阻止。
- `allowlist`：僅允許匹配。
- `full`：允許一切（等同於 elevated）。

### 詢問模式
- `off`：從不詢問。
- `on-miss`：僅當允許清單不匹配時詢問。
- `always`：每次都詢問。

詢問與允許清單**獨立**；允許清單可以與 `always` 或 `on-miss` 一起使用。

### 策略解析（每次 exec）
1) 解析 `exec.host`（tool param → agent 覆蓋 → 全域預設）。
2) 解析 `exec.security` 和 `exec.ask`（相同優先順序）。
3) 如果 host 是 `sandbox`，繼續本地 sandbox exec。
4) 如果 host 是 `gateway` 或 `node`，在該 host 上套用 security + ask 策略。

## 預設安全性
- 預設 `exec.host = sandbox`。
- `gateway` 和 `node` 的預設 `exec.security = deny`。
- 預設 `exec.ask = on-miss`（僅在 security 允許時相關）。
- 如果未設定節點綁定，**代理可以定位任何節點**，但僅在策略允許時。

## 設定介面
### 工具參數
- `exec.host`（可選）：`sandbox | gateway | node`。
- `exec.security`（可選）：`deny | allowlist | full`。
- `exec.ask`（可選）：`off | on-miss | always`。
- `exec.node`（可選）：當 `host=node` 時使用的 node id/name。

### 設定鍵（全域）
- `tools.exec.host`
- `tools.exec.security`
- `tools.exec.ask`
- `tools.exec.node`（預設節點綁定）

### 設定鍵（每個代理）
- `agents.list[].tools.exec.host`
- `agents.list[].tools.exec.security`
- `agents.list[].tools.exec.ask`
- `agents.list[].tools.exec.node`

### 別名
- `/elevated on` = 為代理會話設定 `tools.exec.host=gateway`、`tools.exec.security=full`。
- `/elevated off` = 為代理會話恢復先前的 exec 設定。

## 核准儲存（JSON）
路徑：`~/.openclaw/exec-approvals.json`

目的：
- **執行 host**（gateway 或 node runner）的本地策略 + 允許清單。
- 當無 UI 可用時的詢問回退。
- UI 客戶端的 IPC 憑證。

提議的 schema（v1）：
```json
{
  "version": 1,
  "socket": {
    "path": "~/.openclaw/exec-approvals.sock",
    "token": "base64-opaque-token"
  },
  "defaults": {
    "security": "deny",
    "ask": "on-miss",
    "askFallback": "deny"
  },
  "agents": {
    "agent-id-1": {
      "security": "allowlist",
      "ask": "on-miss",
      "allowlist": [
        {
          "pattern": "~/Projects/**/bin/rg",
          "lastUsedAt": 0,
          "lastUsedCommand": "rg -n TODO",
          "lastResolvedPath": "/Users/user/Projects/.../bin/rg"
        }
      ]
    }
  }
}
```
注意事項：
- 無舊版允許清單格式。
- `askFallback` 僅在需要 `ask` 且無法到達 UI 時套用。
- 檔案權限：`0600`。

## Runner 服務（headless）
### 角色
- 本地強制執行 `exec.security` + `exec.ask`。
- 執行系統指令並返回輸出。
- 為 exec 生命週期發出 Bridge 事件（可選但建議）。

### 服務生命週期
- macOS 上的 Launchd/daemon；Linux/Windows 上的系統服務。
- 核准 JSON 對執行 host 是本地的。
- UI 託管本地 Unix socket；runner 按需連線。

## UI 整合（macOS app）
### IPC
- Unix socket 位於 `~/.openclaw/exec-approvals.sock`（0600）。
- Token 儲存在 `exec-approvals.json`（0600）。
- Peer 檢查：僅相同 UID。
- Challenge/response：nonce + HMAC(token, request-hash) 以防止重放。
- 短 TTL（例如 10 秒）+ max payload + 速率限制。

### 詢問流程（macOS app exec host）
1) Node 服務從 gateway 接收 `system.run`。
2) Node 服務連線到本地 socket 並發送提示/exec 請求。
3) App 驗證 peer + token + HMAC + TTL，然後在需要時顯示對話框。
4) App 在 UI 上下文中執行指令並返回輸出。
5) Node 服務將輸出返回到 gateway。

如果缺少 UI：
- 套用 `askFallback`（`deny|allowlist|full`）。

### 圖表（SCI）
```
Agent -> Gateway -> Bridge -> Node Service (TS)
                         |  IPC (UDS + token + HMAC + TTL)
                         v
                     Mac App (UI + TCC + system.run)
```

## 節點身份 + 綁定
- 使用來自 Bridge 配對的現有 `nodeId`。
- 綁定模型：
  - `tools.exec.node` 將代理限制為特定節點。
  - 如果未設定，代理可以選擇任何節點（策略仍強制執行預設）。
- 節點選擇解析：
  - `nodeId` 精確匹配
  - `displayName`（正規化）
  - `remoteIp`
  - `nodeId` 前綴（>= 6 個字元）

## 事件
### 誰看到事件
- 系統事件是**每個會話**的，並在下一個提示時顯示給代理。
- 儲存在 gateway 記憶體佇列中（`enqueueSystemEvent`）。

### 事件文字
- `Exec started (node=<id>, id=<runId>)`
- `Exec finished (node=<id>, id=<runId>, code=<code>)` + 可選輸出尾部
- `Exec denied (node=<id>, id=<runId>, <reason>)`

### 傳輸
選項 A（建議）：
- Runner 發送 Bridge `event` 幀 `exec.started` / `exec.finished`。
- Gateway `handleBridgeEvent` 將這些對應到 `enqueueSystemEvent`。

選項 B：
- Gateway `exec` 工具直接處理生命週期（僅同步）。

## Exec 流程
### Sandbox host
- 現有 `exec` 行為（Docker 或 unsandboxed 時的 host）。
- 僅在非 sandbox 模式下支援 PTY。

### Gateway host
- Gateway 處理程序在其自己的機器上執行。
- 強制執行本地 `exec-approvals.json`（security/ask/allowlist）。

### Node host
- Gateway 使用 `system.run` 呼叫 `node.invoke`。
- Runner 強制執行本地核准。
- Runner 返回聚合的 stdout/stderr。
- start/finish/deny 的可選 Bridge 事件。

## 輸出上限
- 將組合的 stdout+stderr 限制在 **200k**；為事件保留**尾部 20k**。
- 使用明確後綴截斷（例如，`"… (truncated)"`）。

## Slash 指令
- `/exec host=<sandbox|gateway|node> security=<deny|allowlist|full> ask=<off|on-miss|always> node=<id>`
- 每個代理、每個會話覆蓋；除非透過設定儲存，否則非持久性。
- `/elevated on|off|ask|full` 保持作為 `host=gateway security=full` 的快捷方式（`full` 跳過核准）。

## 跨平台故事
- Runner 服務是可攜式執行目標。
- UI 是可選的；如果缺少，套用 `askFallback`。
- Windows/Linux 支援相同的核准 JSON + socket 協定。

## 實作階段
### 第 1 階段：config + exec 路由
- 為 `exec.host`、`exec.security`、`exec.ask`、`exec.node` 新增設定 schema。
- 更新工具管道以遵守 `exec.host`。
- 新增 `/exec` slash 指令並保持 `/elevated` 別名。

### 第 2 階段：核准儲存 + gateway 強制執行
- 實作 `exec-approvals.json` reader/writer。
- 為 `gateway` host 強制執行允許清單 + 詢問模式。
- 新增輸出上限。

### 第 3 階段：node runner 強制執行
- 更新 node runner 以強制執行允許清單 + 詢問。
- 向 macOS app UI 新增 Unix socket 提示橋接。
- 連線 `askFallback`。

### 第 4 階段：事件
- 為 exec 生命週期新增 node → gateway Bridge 事件。
- 對應到 `enqueueSystemEvent` 以用於代理提示。

### 第 5 階段：UI 修飾
- Mac app：允許清單編輯器、每個代理切換器、詢問策略 UI。
- 節點綁定控制（可選）。

## 測試計畫
- 單元測試：允許清單匹配（glob + 不區分大小寫）。
- 單元測試：策略解析優先順序（tool param → agent 覆蓋 → 全域）。
- 整合測試：node runner deny/allow/ask 流程。
- Bridge 事件測試：node 事件 → 系統事件路由。

## 開放風險
- UI 不可用：確保遵守 `askFallback`。
- 長時間執行的指令：依賴逾時 + 輸出上限。
- 多節點歧義：除非節點綁定或明確節點 param，否則錯誤。

## 相關文件
- [Exec tool](/tools/exec)
- [Exec approvals](/tools/exec-approvals)
- [Nodes](/nodes)
- [Elevated mode](/tools/elevated)
