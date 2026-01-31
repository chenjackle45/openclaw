---
title: "dev-setup(macOS Dev Setup)"
summary: "OpenClaw macOS 應用程式開發者設定指南"
read_when:
  - 設定 macOS 開發環境時
---

# macOS 開發者設定

本指南涵蓋從原始碼建置並運行 OpenClaw macOS 應用程式所需的步驟。

## 先決條件

在建置應用程式之前，確保您已安裝：

1.  **Xcode 26.2+**: Swift 開發所需。
2.  **Node.js 22+ & pnpm**: Gateway、CLI 與打包腳本所需。

## 1. 安裝相依套件

安裝專案層級的相依套件：

```bash
pnpm install
```

## 2. 建置與打包應用程式

要建置 macOS 應用程式並將其打包至 `dist/OpenClaw.app`，請執行：

```bash
./scripts/package-mac-app.sh
```

若您沒有 Apple Developer ID 憑證，腳本會自動使用 **ad-hoc 簽署** (`-`)。

關於開發運行模式、簽署旗標與 Team ID 故障排除，請參閱 macOS 應用程式 README：
https://github.com/openclaw/openclaw/blob/main/apps/macos/README.md

> **注意**: Ad-hoc 簽署的應用程式可能會觸發安全提示。若應用程式啟動即崩潰並顯示 "Abort trap 6"，請參閱 [故障排除](#故障排除) 章節。

## 3. 安裝 CLI

macOS 應用程式預期有一個全域的 `openclaw` CLI 安裝來管理背景任務。

**安裝方式（推薦）：**
1.  開啟 OpenClaw 應用程式。
2.  前往 **General** (一般) 設定頁籤。
3.  點擊 **"Install CLI"**。

或者，手動安裝：
```bash
npm install -g openclaw@<version>
```

## 故障排除

### 建置失敗：工具鏈或 SDK 不相符
macOS 應用程式建置預期使用最新的 macOS SDK 與 Swift 6.2 工具鏈。

**系統相依性（必需）：**
- **軟體更新中可用的最新 macOS 版本**（Xcode 26.2 SDKs 所需）
- **Xcode 26.2** (Swift 6.2 工具鏈)

**檢查：**
```bash
xcodebuild -version
xcrun swift --version
```

若版本不符，請更新 macOS/Xcode 並重新執行建置。

### 應用程式在授權時崩潰
若您嘗試允許 **Speech Recognition** (語音辨識) 或 **Microphone** (麥克風) 存取時應用程式崩潰，可能是 TCC 快取損毀或簽章不符導致。

**修復：**
1. 重置 TCC 權限：
   ```bash
   tccutil reset All bot.molt.mac.debug
   ```
2. 若失敗，暫時變更 [`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 中的 `BUNDLE_ID` 以強制 macOS 視為全新應用程式。

### Gateway 無限顯示 "Starting..."
若 Gateway 狀態停留在 "Starting..."，檢查是否由殭屍行程佔用了通訊埠：

```bash
openclaw gateway status
openclaw gateway stop

# 若您未使用 LaunchAgent (開發模式 / 手動運行)，尋找聆聽者：
lsof -nP -iTCP:18789 -sTCP:LISTEN
```
若手動執行的行程佔用了通訊埠，請停止該行程 (Ctrl+C)。若無效，殺除上方找到的 PID。
