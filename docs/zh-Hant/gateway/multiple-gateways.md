---
title: "multiple-gateways(Multiple Gateways)"
summary: "在單一主機上運行多個 OpenClaw Gateways (Isolation, Ports, 與 Profiles)"
read_when:
  - 在同一台機器上運行超過一個 Gateway 時
  - 需要每個 Gateway 隔離 Config/State/Ports 時
---

# 多重 Gateways (同一主機)

大多數設定應使用單一 Gateway，因為單一 Gateway 即可處理多個訊息連線與 Agents。若您需要更強的隔離或冗餘 (例如：救援機器人 Rescue Bot)，請使用隔離的 Profiles/Ports 運行分開的 Gateways。

## 隔離檢查清單 (必要)
- `OPENCLAW_CONFIG_PATH` — Per-instance 設定檔
- `OPENCLAW_STATE_DIR` — Per-instance Sessions, Creds, Caches
- `agents.defaults.workspace` — Per-instance Workspace Root
- `gateway.port` (或 `--port`) — 每個 Instance 唯一
- 推導的 Ports (Browser/Canvas) 絕不可重疊

若這些共用，您會遇到 Config Races 與 Port Conflicts。

## 推薦: Profiles (`--profile`)

Profiles 自動界定 (Scope) `OPENCLAW_STATE_DIR` + `OPENCLAW_CONFIG_PATH` 並為服務名稱加上後綴。

```bash
# main
openclaw --profile main setup
openclaw --profile main gateway --port 18789

# rescue
openclaw --profile rescue setup
openclaw --profile rescue gateway --port 19001
```

Per-profile 服務:
```bash
openclaw --profile main gateway install
openclaw --profile rescue gateway install
```

## Rescue-bot 指南

在同一台主機上運行第二個 Gateway，擁有其自己的：
- Profile/Config
- State Dir
- Workspace
- Base Port (加上 Derived Ports)

這讓 Rescue Bot 與 Main Bot 隔離，因此若 Primary Bot 當機，它可以用於除錯或套用 Config 變更。

Port 間距 (Spacing): 在 Base Ports 之間至少保留 20 個 Ports，以免推導出的 Browser/Canvas/CDP Ports 發生衝突。

### 如何安裝 (Rescue Bot)

```bash
# Main bot (既有或全新，不帶 --profile 參數)
# 運行在 Port 18789 + Chrome CDC/Canvas/... Ports 
openclaw onboard
openclaw gateway install

# Rescue bot (隔離的 Profile + Ports)
openclaw --profile rescue onboard
# 註: 
# - Workspace 名稱預設會加上 -rescue 後綴
# - Port 應至少為 18789 + 20 Ports, 
#   最好選擇完全不同的 Base Port, 例如 19789,
# - 剩餘的 Onboarding 與正常相同

# 安裝服務 (若 Onboarding 期間未自動發生)
openclaw --profile rescue gateway install
```

## Port Mapping (Derived)

Base Port = `gateway.port` (或 `OPENCLAW_GATEWAY_PORT` / `--port`)。

- 瀏覽器控制服務連接埠 = Base + 2 (僅限 Loopback)
- `canvasHost.port = base + 4`
- Browser Profile CDP Ports 自動從 `browser.controlPort + 9 .. + 108` 分配

若您在 Config 或 Env 中覆蓋其中任何一個，必須保持每個 Instance 唯一。

## Browser/CDP 註記 (常見陷阱)

- **不要** 在多個 Instances 上將 `browser.cdpUrl` 固定為相同數值。
- 每個 Instance 需要其自己的 Browser Control Port 與 CDP Range (從其 Gateway Port 推導)。
- 若您需要顯式 CDP Ports，請每個 Instance 設定 `browser.profiles.<name>.cdpPort`。
- Remote Chrome: 使用 `browser.profiles.<name>.cdpUrl` (Per profile, per instance)。

## 手動 Env 範例

```bash
OPENCLAW_CONFIG_PATH=~/.openclaw/main.json \
OPENCLAW_STATE_DIR=~/.openclaw-main \
openclaw gateway --port 18789

OPENCLAW_CONFIG_PATH=~/.openclaw/rescue.json \
OPENCLAW_STATE_DIR=~/.openclaw-rescue \
openclaw gateway --port 19001
```

## 快速檢查

```bash
openclaw --profile main status
openclaw --profile rescue status
openclaw --profile rescue browser status
```
