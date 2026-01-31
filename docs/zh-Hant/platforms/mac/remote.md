---
title: "remote(Remote over SSH)"
summary: "透過 SSH 控制遠端 OpenClaw Gateway 的 macOS 應用程式流程"
read_when:
  - 設定或除錯遠端 macOS 控制時
---

# 遠端 OpenClaw (macOS ⇄ 遠端主機)

此流程讓 macOS 應用程式成為運行於另一台主機（桌面/伺服器）上的 OpenClaw Gateway 的完整遙控器。這就是應用程式的 **Remote over SSH**（遠端執行）功能。所有功能——健康檢查、語音喚醒轉發與 Web Chat——皆重複使用 *Settings → General* 中的相同遠端 SSH 設定。

## 模式

- **Local (此 Mac)**: 所有東西皆在筆電上運行。不涉及 SSH。
- **Remote over SSH (預設)**: OpenClaw 指令在遠端主機上執行。Mac 應用程式使用 `-o BatchMode` 加上您選擇的身分/金鑰與本地通訊埠轉發 (port-forward) 開啟 SSH 連線。
- **Remote direct (ws/wss)**: 無 SSH 通道。Mac 應用程式直接連接至 Gateway URL（例如，透過 Tailscale Serve 或公開 HTTPS 反向代理）。

## 遠端傳輸 (Remote Transports)

Remote 模式支援兩種傳輸方式：
- **SSH tunnel** (預設): 使用 `ssh -N -L ...` 將 Gateway 通訊埠轉發至 localhost。Gateway 會看到節點 IP 為 `127.0.0.1`，因為通道是 loopback。
- **Direct (ws/wss)**: 直接連接至 Gateway URL。Gateway 會看到真實的客戶端 IP。

## 遠端主機先決條件

1) 安裝 Node + pnpm 並建置/安裝 OpenClaw CLI (`pnpm install && pnpm build && pnpm link --global`)。
2) 確保 `openclaw` 在非互動式 Shell 的 PATH 中（若需要，建立 symlink 至 `/usr/local/bin` 或 `/opt/homebrew/bin`）。
3) 開啟 SSH 金鑰認證。我們推薦使用 **Tailscale** IP 以獲得穩定的非 LAN 可達性。

## macOS 應用程式設定

1) 開啟 *Settings → General*。
2) 在 **OpenClaw runs** 下，選擇 **Remote over SSH** 並設定：
   - **Transport**: **SSH tunnel** 或 **Direct (ws/wss)**。
   - **SSH target**: `user@host` (可選 `:port`)。
     - 若 Gateway 位於同一 LAN 並廣播 Bonjour，從發現列表中選擇它以自動填寫此欄位。
   - **Gateway URL** (僅限 Direct): `wss://gateway.example.ts.net` (或 `ws://...` 用於 Local/LAN)。
   - **Identity file** (進階): 您的金鑰路徑。
   - **Project root** (進階): 用於指令的遠端 Checkout 路徑。
   - **CLI path** (進階): 可選的可執行 `openclaw` 入口點/二進位檔路徑（廣播時自動填寫）。
3) 點擊 **Test remote**。成功表示遠端 `openclaw status --json` 執行正確。失敗通常表示 PATH/CLI 問題；exit 127 表示遠端找不到 CLI。
4) 健康檢查與 Web Chat 現在會自動通過此 SSH 通道運行。

## Web Chat

- **SSH tunnel**: Web Chat 透過轉發的 WebSocket 控制通訊埠（預設 18789）連接至 Gateway。
- **Direct (ws/wss)**: Web Chat 直接連接至配置的 Gateway URL。
- 不再有獨立的 WebChat HTTP 伺服器。

## 權限

- 遠端主機需要與本地相同的 TCC 核准（自動化、輔助使用、螢幕錄製、麥克風、語音辨識、通知）。在該機器上執行 Onboarding 以一次性授權。
- 節點透過 `node.list` / `node.describe` 廣播其權限狀態，以便 Agent 知道哪些功能可用。

## 安全性注意事項

- 遠端主機優先使用 loopback bind，並透過 SSH 或 Tailscale 連接。
- 若將 Gateway 綁定至非 loopback 介面，請要求 token/密碼認證。
- 參閱 [Security](/gateway/security) 與 [Tailscale](/gateway/tailscale)。

## WhatsApp 登入流程 (遠端)

- **在遠端主機上** 執行 `openclaw channels login --verbose`。用手機上的 WhatsApp 掃描 QR Code。
- 若認證過期，在該主機上重新執行登入。健康檢查會顯示連結問題。

## 故障排除

- **exit 127 / not found**: `openclaw` 不在非登入 Shell 的 PATH 中。將其加入 `/etc/paths`、您的 Shell rc，或 symlink 至 `/usr/local/bin`/`/opt/homebrew/bin`。
- **Health probe failed**: 檢查 SSH 可達性、PATH，以及 Baileys 是否已登入 (`openclaw status --json`)。
- **Web Chat 卡住**: 確認遠端主機上的 Gateway 正在運行，且轉發的通訊埠與 Gateway WS 通訊埠相符；UI 需要健康的 WS 連線。
- **Node IP 顯示 127.0.0.1**: SSH 通道的預期行為。若希望 Gateway 看到真實客戶端 IP，請將 **Transport** 切換為 **Direct (ws/wss)**。
- **Voice Wake**: 觸發詞在 Remote 模式下會自動轉發；無需獨立的轉發器。

## 通知音效

使用 `openclaw` 與 `node.invoke` 為每個通知選擇音效，例如：

```bash
openclaw nodes notify --node <id> --title "Ping" --body "Remote gateway ready" --sound Glass
```

應用程式中不再有全域的「預設音效」開關；呼叫者針對每個請求選擇音效（或無音效）。
