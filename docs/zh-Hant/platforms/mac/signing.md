---
title: "signing(macOS Signing)"
summary: "由打包腳本產生的 macOS 除錯建置簽署步驟"
read_when:
  - 建置或簽署 mac 除錯建置時
---

# mac 簽署 (除錯建置)

此應用程式通常由 [`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 建置，該腳本現在會：

- 設定穩定的 Debug Bundle Identifier: `ai.openclaw.mac.debug`
- 寫入帶有該 Bundle ID 的 Info.plist (可透過 `BUNDLE_ID=...` 覆寫)
- 呼叫 [`scripts/codesign-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/codesign-mac-app.sh) 簽署主要二進位檔與應用程式套件，使 macOS 將每次重建視為相同的已簽署套件，並保留 TCC 權限（通知、輔助使用、螢幕錄製、麥克風、語音）。為了權限穩定，請使用真實的簽署身分；Ad-hoc 簽署需手動啟用且較脆弱 (參見 [macOS permissions](/platforms/mac/permissions))。
- 預設使用 `CODESIGN_TIMESTAMP=auto`；這會啟用 Developer ID 簽章的可信任時間戳記。設定 `CODESIGN_TIMESTAMP=off` 可跳過時間戳記（適用於離線除錯建置）。
- 將建置中繼資料注入 Info.plist: `OpenClawBuildTimestamp` (UTC) 與 `OpenClawGitCommit` (短雜湊)，以便 About 面板顯示版本、git 資訊與 debug/release 通道。
- **打包需要 Node 22+**: 腳本會執行 TS 建置與 Control UI 建置。
- 從環境變數讀取 `SIGN_IDENTITY`。將 `export SIGN_IDENTITY="Apple Development: Your Name (TEAMID)"` (或您的 Developer ID Application 憑證) 加入您的 shell rc 以始終使用您的憑證簽署。Ad-hoc 簽署需要透過 `ALLOW_ADHOC_SIGNING=1` 或 `SIGN_IDENTITY="-"` 明確啟用 (不建議用於測試權限)。
- 簽署後執行 Team ID 稽核，若應用程式套件內有任何 Mach-O 由不同 Team ID 簽署則失敗。設定 `SKIP_TEAM_ID_CHECK=1` 可繞過此檢查。

## 用法

```bash
# 從 repo 根目錄
scripts/package-mac-app.sh               # 自動選擇身分；若未找到則錯誤
SIGN_IDENTITY="Developer ID Application: Your Name" scripts/package-mac-app.sh   # 真實憑證
ALLOW_ADHOC_SIGNING=1 scripts/package-mac-app.sh    # Ad-hoc (權限不會保留)
SIGN_IDENTITY="-" scripts/package-mac-app.sh        # 明確 Ad-hoc (相同警告)
DISABLE_LIBRARY_VALIDATION=1 scripts/package-mac-app.sh   # 僅限開發：Sparkle Team ID 不相符的解決方案
```

### Ad-hoc 簽署注意事項
當使用 `SIGN_IDENTITY="-"` (Ad-hoc) 簽署時，腳本會自動停用 **Hardened Runtime** (`--options runtime`)。這是防止應用程式嘗試載入未共享相同 Team ID 的嵌入式框架（如 Sparkle）時崩潰所必需的。Ad-hoc 簽章也會破壞 TCC 權限持久性；復原步驟請參閱 [macOS permissions](/platforms/mac/permissions)。

## About 頁面的建置中繼資料

`package-mac-app.sh` 會在套件上標記：
- `OpenClawBuildTimestamp`: 打包時的 ISO8601 UTC
- `OpenClawGitCommit`: 短 Git 雜湊 (若無法取得則為 `unknown`)

About 頁籤讀取這些鍵值以顯示版本、建置日期、Git Commit 以及是否為 Debug 建置 (透過 `#if DEBUG`)。更改程式碼後運行打包器以更新這些數值。

## 原因

TCC 權限綁定於 Bundle Identifier *以及* 程式碼簽章。未簽署且 UUID 不斷變化的 Debug 建置會導致 macOS 在每次重建後忘記授權。簽署二進位檔 (預設 Ad-hoc) 並保持固定的 Bundle ID/路徑 (`dist/OpenClaw.app`) 可在建置之間保留授權，這與 VibeTunnel 的做法一致。
