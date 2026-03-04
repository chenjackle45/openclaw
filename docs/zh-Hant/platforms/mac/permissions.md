---
summary: "macOS 權限持久化（TCC）和簽署需求"
read_when:
  - 偵錯缺失或卡住的 macOS 權限提示
  - 打包或簽署 macOS 應用
  - 變更套件 ID 或應用安裝路徑
title: "macOS Permissions（macOS 權限）"
---

# macOS 權限（TCC）

macOS 權限授予很脆弱。TCC 將權限授予與應用的程式碼簽名、套件識別碼和磁碟上路徑相關聯。如果其中任何一個改變，macOS 會將應用視為新的，並可能會丟棄或隱藏提示。

## 穩定權限的需求

- 相同路徑：從固定位置執行應用（針對 OpenClaw，`dist/OpenClaw.app`）。
- 相同套件識別碼：變更套件 ID 會建立新的權限身分。
- 已簽署的應用：未簽署或臨時簽署的構建不會持久化權限。
- 一致的簽名：使用真正的 Apple 開發或開發者 ID 憑證，以便簽名在重新構建中保持穩定。

臨時簽名每次構建都會產生新身分。macOS 會忘記之前的授予，直到清除過時項目，提示可能會完全消失。

## 提示消失時的恢復檢查清單

1. 結束應用。
2. 在系統設定 -> 隱私與安全中移除應用項目。
3. 從相同路徑重新啟動應用並重新授予權限。
4. 如果提示仍未出現，使用 `tccutil` 重設 TCC 項目並重試。
5. 有些權限只有在完整 macOS 重新啟動後才會重新出現。

範例重設（視需要替換套件 ID）：

```bash
sudo tccutil reset Accessibility ai.openclaw.mac
sudo tccutil reset ScreenCapture ai.openclaw.mac
sudo tccutil reset AppleEvents
```

## 檔案和資料夾權限（桌面/文件/下載）

macOS 也可能會對終端機/背景處理程序限制桌面、文件和下載。如果檔案讀取或目錄清單懸掛，請授予對執行檔案操作的相同處理程序內容的存取權（例如終端機/iTerm、LaunchAgent 啟動的應用或 SSH 處理程序）。

因應措施：如果您想避免每個資料夾授予，請將檔案移至 OpenClaw 工作區（`~/.openclaw/workspace`）。

如果您測試權限，請始終使用真正的憑證簽署。臨時構建僅適用於權限不重要的快速本機執行。
