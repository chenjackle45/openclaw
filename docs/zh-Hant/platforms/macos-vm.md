---
title: "macos-vm(macOS VMs)"
summary: "在沙盒 macOS VM (本地或託管) 中運行 OpenClaw，適用於隔離或 iMessage 需求"
read_when:
  - 想要將 OpenClaw 與主要的 macOS 環境隔離時
  - 想要在沙盒中整合 iMessage (BlueBubbles) 時
  - 想要一個可重置且可複製的 macOS 環境時
  - 想要比較本地與託管 macOS VM 選項時
---

# 在 macOS VM 上運行 OpenClaw (沙盒化)

## 推薦預設方案 (多數使用者)

- **小型 Linux VPS**：用於全天候運行的 Gateway，成本低。參閱 [VPS hosting](/vps)。
- **專用硬體** (Mac mini 或 Linux 主機)：若您需要完全控制權與**住宅 IP** 用於瀏覽器自動化。許多網站會封鎖資料中心 IP，因此本地瀏覽通常效果較好。
- **混合模式**：將 Gateway 放在便宜的 VPS 上，並在需要瀏覽器/UI 自動化時將您的 Mac 作為**節點**連接。參閱 [Nodes](/nodes) 與 [Gateway remote](/gateway/remote)。

當您特別需要 macOS 專屬功能 (iMessage/BlueBubbles) 或希望與日常使用的 Mac 嚴格隔離時，請使用 macOS VM。

## macOS VM 選項

### 您 Apple Silicon Mac 上的本地 VM (Lume)

使用 [Lume](https://cua.ai/docs/lume) 在您現有的 Apple Silicon Mac 上運行沙盒化的 macOS VM 中的 OpenClaw。

這提供您：
- 完全隔離的 macOS 環境（您的主機保持乾淨）
- 透過 BlueBubbles 支援 iMessage（在 Linux/Windows 上無法實現）
- 透過複製 VM 瞬間重置
- 無需額外硬體或雲端成本

### 託管 Mac 供應商 (雲端)

若您想要雲端的 macOS，託管 Mac 供應商也是可行的：
- [MacStadium](https://www.macstadium.com/) (託管 Macs)
- 其他託管 Mac 供應商也可以；請依照他們的 VM + SSH 文件操作

一旦您擁有 macOS VM 的 SSH 存取權，請從下方的步驟 6 繼續。

---

## 快速路徑 (Lume, 進階使用者)

1. 安裝 Lume
2. `lume create openclaw --os macos --ipsw latest`
3. 完成設定輔助程式，啟用遠端登入 (SSH)
4. `lume run openclaw --no-display`
5. SSH 進入，安裝 OpenClaw，配置頻道
6. 完成

---

## 需求 (Lume)

- Apple Silicon Mac (M1/M2/M3/M4)
- 主機需為 macOS Sequoia 或更新版本
- 每個 VM 約需 60 GB 可用磁碟空間
- 約 20 分鐘時間

---

## 1) 安裝 Lume

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trycua/cua/main/libs/lume/scripts/install.sh)"
```

若 `~/.local/bin` 不在您的 PATH 中：

```bash
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.zshrc && source ~/.zshrc
```

驗證：

```bash
lume --version
```

文件：[Lume Installation](https://cua.ai/docs/lume/guide/getting-started/installation)

---

## 2) 建立 macOS VM

```bash
lume create openclaw --os macos --ipsw latest
```

這會下載 macOS 並建立 VM。VNC 視窗會自動開啟。

注意：下載時間取決於您的網路連線。

---

## 3) 完成設定輔助程式

在 VNC 視窗中：
1. 選擇語言與地區
2. 跳過 Apple ID（若稍後需要 iMessage 則登入）
3. 建立使用者帳戶（請記住使用者名稱與密碼）
4. 跳過所有選用功能

設定完成後，啟用 SSH：
1. 開啟 System Settings → General → Sharing
2. 啟用 "Remote Login"

---

## 4) 取得 VM 的 IP 位址

```bash
lume get openclaw
```

尋找 IP 位址（通常為 `192.168.64.x`）。

---

## 5) SSH 進入 VM

```bash
ssh youruser@192.168.64.X
```

將 `youruser` 替換為您建立的帳戶，並將 IP 替換為您的 VM IP。

---

## 6) 安裝 OpenClaw

在 VM 內部：

```bash
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

依照 Onboarding 提示設定您的模型服務供應商 (Anthropic, OpenAI 等)。

---

## 7) 配置頻道

編輯設定檔：

```bash
nano ~/.openclaw/openclaw.json
```

新增您的頻道：

```json
{
  "channels": {
    "whatsapp": {
      "dmPolicy": "allowlist",
      "allowFrom": ["+15551234567"]
    },
    "telegram": {
      "botToken": "YOUR_BOT_TOKEN"
    }
  }
}
```

接著登入 WhatsApp (掃瞄 QR Code)：

```bash
openclaw channels login
```

---

## 8) 無顯示模式運行 VM

停止 VM 並以無顯示模式重啟：

```bash
lume stop openclaw
lume run openclaw --no-display
```

VM 會在背景運行。OpenClaw 的守護進程 (daemon) 會保持 Gateway 運行。

檢查狀態：

```bash
ssh youruser@192.168.64.X "openclaw status"
```

---

## 加分項目：iMessage 整合

這是在 macOS 上運行的殺手級功能。使用 [BlueBubbles](https://bluebubbles.app) 將 iMessage 加入 OpenClaw。

在 VM 內部：

1. 從 bluebubbles.app 下載 BlueBubbles
2. 使用您的 Apple ID 登入
3. 啟用 Web API 並設定密碼
4. 將 BlueBubbles webhook 指向您的 Gateway
   （範例：`https://your-gateway-host:3000/bluebubbles-webhook?password=<password>`）

加入至您的 OpenClaw 配置：

```json
{
  "channels": {
    "bluebubbles": {
      "serverUrl": "http://localhost:1234",
      "password": "your-api-password",
      "webhookPath": "/bluebubbles-webhook"
    }
  }
}
```

重新啟動 Gateway。現在您的 Agent 可以發送與接收 iMessage。

詳細設定：[BlueBubbles channel](/channels/bluebubbles)

---

## 儲存黃金映像檔 (Golden Image)

在進一步客製化之前，為您的乾淨狀態建立快照：

```bash
lume stop openclaw
lume clone openclaw openclaw-golden
```

隨時重置：

```bash
lume stop openclaw && lume delete openclaw
lume clone openclaw-golden openclaw
lume run openclaw --no-display
```

---

## 全天候運行 (24/7)

透過以下方式保持 VM 運行：
- 保持 Mac 接上電源
- 在 System Settings → Energy Saver 中停用睡眠
- 需要時使用 `caffeinate`

若需真正全天候運行，建議使用專用的 Mac mini 或小型 VPS。參閱 [VPS hosting](/vps)。

---

## 故障排除

| 問題 | 解決方案 |
|---------|----------|
| 無法 SSH 進入 VM | 檢查 VM 的 System Settings 中是否啟用 "Remote Login" |
| 未顯示 VM IP | 等待 VM 完全開機，再次執行 `lume get openclaw` |
| 找不到 Lume 指令 | 將 `~/.local/bin` 加入您的 PATH |
| WhatsApp QR 無法掃描 | 執行 `openclaw channels login` 時確保您是登入到 VM（非主機） |

---

## 相關文件

- [VPS hosting](/vps)
- [Nodes](/nodes)
- [Gateway remote](/gateway/remote)
- [BlueBubbles channel](/channels/bluebubbles)
- [Lume Quickstart](https://cua.ai/docs/lume/guide/getting-started/quickstart)
- [Lume CLI Reference](https://cua.ai/docs/lume/reference/cli-reference)
- [Unattended VM Setup](https://cua.ai/docs/lume/guide/fundamentals/unattended-setup) (進階)
- [Docker Sandboxing](/install/docker) (替代的隔離方案)
