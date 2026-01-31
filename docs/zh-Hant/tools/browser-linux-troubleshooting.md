---
title: "Browser linux troubleshooting(Linux 瀏覽器疑難排解)"
summary: "修復 Linux 在執行 OpenClaw 瀏覽器控制時遇到的 Chrome/Brave/Edge/Chromium CDP 啟動問題"
read_when: "在 Linux 上瀏覽器控制失敗時，特別是使用 Snap 版 Chromium 時"
---

# 瀏覽器疑難排解 (Linux)

## 問題描述：「Failed to start Chrome CDP on port 18800」

OpenClaw 嘗試啟動瀏覽器時出現以下錯誤：
```
{"error":"Error: Failed to start Chrome CDP on port 18800 for profile \"openclaw\"."}
```

### 根本原因
在 Ubuntu（以及許多 Linux 發行版）中，預設安裝的 Chromium 是 **Snap 套件**。Snap 的 AppArmor 限制會干擾 OpenClaw 對瀏覽器進程的生成與監控。通常使用 `apt install chromium` 安裝的其實只是一個導向 Snap 的外殼。

### 解決方案 1：安裝 Google Chrome（建議做法）
安裝官方的 Google Chrome `.deb` 套件，它不受 Snap 的沙盒限制：

```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y # 若有相依性錯誤請執行此行
```

接著更新您的 `~/.openclaw/openclaw.json`：
```json
{
  "browser": {
    "enabled": true,
    "executablePath": "/usr/bin/google-chrome-stable",
    "headless": true,
    "noSandbox": true
  }
}
```

### 解決方案 2：使用 Snap 版 Chromium 並搭配「僅附加 (Attach-Only)」模式
若您必須使用 Snap 版，請配置 OpenClaw 僅嘗試連線至已手動啟動的瀏覽器：

1. **更新配置**：設定 `browser.attachOnly: true`。
2. **手動啟動 Chromium**：
   ```bash
   chromium-browser --headless --no-sandbox --disable-gpu \
     --remote-debugging-port=18800 \
     --user-data-dir=$HOME/.openclaw/browser/openclaw/user-data \
     about:blank &
   ```
3. **（進階）建立 systemd 服務**：設定開機自動啟動上述指令。

## 驗證瀏覽器是否運作
使用 `curl` 測試本地 API：
```bash
# 查看狀態
curl -s http://127.0.0.1:18791/ | jq '{running, pid, chosenBrowser}'
# 啟動並查看分頁
curl -s -X POST http://127.0.0.1:18791/start
curl -s http://127.0.0.1:18791/tabs
```

## 常見問題：「Chrome extension relay is running, but no tab is connected」
這表示您正在使用 `chrome` 設定檔（擴充功能轉發模式），系統正在等待擴充功能與分頁建立連線。
- **修復方式 1**：改用受管瀏覽器 `openclaw browser start --browser-profile openclaw`。
- **修復方式 2**：安裝擴充功能，開啟分頁後點擊擴充功能圖示進行連線。
