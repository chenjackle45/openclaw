---
title: "logging(macOS Logging)"
summary: "OpenClaw 日誌: 輪替診斷檔案日誌 + 統一日誌隱私旗標"
read_when:
  - 擷取 macOS 日誌或調查私人資料日誌時
  - 除錯語音喚醒/會話生命週期問題時
---

# 日誌 (macOS)

## 輪替診斷檔案日誌 (Debug Pane)
OpenClaw 透過 swift-log (預設為 Unified Logging) 路由 macOS 應用程式日誌，並可在您需要持久化擷取時，將本地輪替 (rotating) 檔案日誌寫入磁碟。

- 詳細程度 (Verbosity): **Debug pane → Logs → App logging → Verbosity**
- 啟用: **Debug pane → Logs → App logging → “Write rolling diagnostics log (JSONL)”**
- 位置: `~/Library/Logs/OpenClaw/diagnostics.jsonl` (自動輪替；舊檔案會加上後綴 `.1`, `.2`, …)
- 清除: **Debug pane → Logs → App logging → “Clear”**

注意：
- 此功能 **預設為關閉**。僅在主動除錯時啟用。
- 請將此檔案視為敏感資料；未經審查請勿分享。

## macOS Unified Logging 私人資料

Unified Logging 會遮蔽大部分 payload，除非子系統選擇啟用 `privacy -off`。根據 Peter 於 2025 年撰寫的 macOS [logging privacy shenanigans](https://steipete.me/posts/2025/logging-privacy-shenanigans)，這由 `/Library/Preferences/Logging/Subsystems/` 中以子系統名稱為鍵值的 plist 控制。僅有新產生的日誌項目會套用此旗標，因此請在重現問題前啟用它。

## 為 OpenClaw (`bot.molt`) 啟用
- 先將 plist 寫入暫存檔，再以 root 身份原子性地安裝：

```bash
cat <<'EOF' >/tmp/bot.molt.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>DEFAULT-OPTIONS</key>
    <dict>
        <key>Enable-Private-Data</key>
        <true/>
    </dict>
</dict>
</plist>
EOF
sudo install -m 644 -o root -g wheel /tmp/bot.molt.plist /Library/Preferences/Logging/Subsystems/bot.molt.plist
```

- 無需重新開機；logd 會迅速偵測到檔案變更，但僅有新的日誌行會包含私人 payload。
- 使用現有輔助工具查看更豐富的輸出，例如 `./scripts/clawlog.sh --category WebChat --last 5m`。

## 除錯後停用
- 移除覆蓋設定：`sudo rm /Library/Preferences/Logging/Subsystems/bot.molt.plist`。
- 可選：執行 `sudo log config --reload` 強制 logd 立即丟棄覆蓋設定。
- 請記住此介面可能包含電話號碼與訊息內文；僅在主動需要額外細節時保留該 plist。
