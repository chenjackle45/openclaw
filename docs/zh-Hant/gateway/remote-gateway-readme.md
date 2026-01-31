---
title: "remote-gateway-readme(Running OpenClaw.app with a Remote Gateway)"
summary: "OpenClaw.app 連線至 Remote Gateway 的 SSH Tunnel 設定"
read_when: "透過 SSH 將 macOS App 連線至 Remote Gateway 時"
---

# 使用 Remote Gateway 運行 OpenClaw.app

OpenClaw.app 使用 SSH Tunneling 連線至 Remote Gateway。此指南顯示如何設定它。

## 概觀

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Machine                          │
│                                                              │
│  OpenClaw.app ──► ws://127.0.0.1:18789 (local port)           │
│                     │                                        │
│                     ▼                                        │
│  SSH Tunnel ────────────────────────────────────────────────│
│                     │                                        │
21: └─────────────────────┼──────────────────────────────────────┘
22:                       │
23:                       ▼
24: ┌─────────────────────────────────────────────────────────────┐
25: │                         Remote Machine                        │
26: │                                                              │
27: │  Gateway WebSocket ──► ws://127.0.0.1:18789 ──►              │
28: │                                                              │
29: └─────────────────────────────────────────────────────────────┘
```

## 快速設定

### 步驟 1: 新增 SSH Config

編輯 `~/.ssh/config` 並新增：

```ssh
Host remote-gateway
    HostName <REMOTE_IP>          # e.g., 172.27.187.184
    User <REMOTE_USER>            # e.g., jefferson
    LocalForward 18789 127.0.0.1:18789
    IdentityFile ~/.ssh/id_rsa
```

將 `<REMOTE_IP>` 與 `<REMOTE_USER>` 替換為您的數值。

### 步驟 2: 複製 SSH Key

將您的 Public Key 複製到 Remote Machine (輸入密碼一次)：

```bash
ssh-copy-id -i ~/.ssh/id_rsa <REMOTE_USER>@<REMOTE_IP>
```

### 步驟 3: 設定 Gateway Token

```bash
launchctl setenv OPENCLAW_GATEWAY_TOKEN "<your-token>"
```

### 步驟 4: 啟動 SSH Tunnel

```bash
ssh -N remote-gateway &
```

### 步驟 5: 重啟 OpenClaw.app

```bash
# Quit OpenClaw.app (⌘Q), then reopen:
open /path/to/OpenClaw.app
```

App 現在將透過 SSH Tunnel 連線至 Remote Gateway。

---

## 登入時自動啟動 Tunnel

若要讓 SSH Tunnel 在您登入時自動啟動，建立一個 Launch Agent。

### 建立 PLIST 檔案

將此儲存為 `~/Library/LaunchAgents/bot.molt.ssh-tunnel.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>bot.molt.ssh-tunnel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/ssh</string>
        <string>-N</string>
        <string>remote-gateway</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

### 載入 Launch Agent

```bash
launchctl bootstrap gui/$UID ~/Library/LaunchAgents/bot.molt.ssh-tunnel.plist
```

Tunnel 現在將：
- 在您登入時自動啟動
- 若崩潰會重新啟動
- 在背景持續運行

Legacy 註記: 若存在任何殘留的 `com.openclaw.ssh-tunnel` LaunchAgent，請移除它。

---

## 故障排除

**檢查 Tunnel 是否在運行:**

```bash
ps aux | grep "ssh -N remote-gateway" | grep -v grep
lsof -i :18789
```

**重啟 Tunnel:**

```bash
launchctl kickstart -k gui/$UID/bot.molt.ssh-tunnel
```

**停止 Tunnel:**

```bash
launchctl bootout gui/$UID/bot.molt.ssh-tunnel
```

---

## 運作原理

| 元件 | 作用 |
|-----------|--------------|
| `LocalForward 18789 127.0.0.1:18789` | 將 Local Port 18789 轉發至 Remote Port 18789 |
| `ssh -N` | SSH 而不執行遠端指令 (僅 Port Forwarding) |
| `KeepAlive` | 若崩潰自動重啟 Tunnel |
| `RunAtLoad` | 在 Agent 載入時啟動 Tunnel |

OpenClaw.app 連線至您 Client Machine 上的 `ws://127.0.0.1:18789`。SSH Tunnel 將該連線轉發至運行 Gateway 的 Remote Machine 上的 Port 18789。
