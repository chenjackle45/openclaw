---
title: "permissions(macOS Permissions)"
summary: "macOS 權限持久性 (TCC) 與簽署需求"
read_when:
  - 除錯遺失或卡住的 macOS 權限提示時
  - 打包或簽署 macOS 應用程式時
  - 變更 Bundle ID 或應用程式安裝路徑時
---

# macOS 權限 (TCC)

macOS 的權限授權相當脆弱。TCC 將權限授權與應用程式的程式碼簽章 (code signature)、Bundle Identifier 以及磁碟路徑綁定。若其中任何一項變更，macOS 會將應用程式視為新的應用程式，並可能移除或隱藏提示。

## 穩定權限的需求

- 相同路徑：從固定位置運行應用程式（OpenClaw 為 `dist/OpenClaw.app`）。
- 相同 Bundle Identifier：變更 Bundle ID 會建立新的權限身分。
- 已簽署的應用程式：未簽署或 ad-hoc 簽署的建置不會持久保存權限。
- 一致的簽章：使用真實的 Apple Development 或 Developer ID 憑證，以便簽章在多次重建後保持穩定。

Ad-hoc 簽章會在每次建置時產生新的身分。macOS 會忘記先前的授權，且在清除陳舊項目之前，提示可能會完全消失。

## 當提示消失時的復原檢查清單

1. 退出應用程式。
2. 移除 System Settings -> Privacy & Security 中的應用程式項目。
3. 從相同路徑重新啟動應用程式並重新授權權限。
4. 若提示仍未出現，使用 `tccutil` 重置 TCC 項目並重試。
5. 部分權限僅在 macOS 完全重啟後才會重新出現。

重置範例（視需要替換 Bundle ID）：

```bash
sudo tccutil reset Accessibility bot.molt.mac
sudo tccutil reset ScreenCapture bot.molt.mac
sudo tccutil reset AppleEvents
```

若您正在測試權限，請務必使用真實憑證簽署。Ad-hoc 建置僅適用於不介意權限的快速本地運行。
