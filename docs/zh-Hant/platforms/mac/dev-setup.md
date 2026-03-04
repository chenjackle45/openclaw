---
summary: "macOS app 開發人員的設定指南"
read_when:
  - Setting up the macOS development environment
title: "macOS Dev Setup（macOS Dev 設定）"
---

# macOS 開發人員設定

此指南涵蓋從原始碼構建和執行 OpenClaw macOS 應用所需的步驟。

## 先決條件

構建應用之前，請確保您已安裝下列項目：

1. **Xcode 26.2+**：Swift 開發必須。
2. **Node.js 22+ & pnpm**：閘道、CLI 和打包指令碼必須。

## 1. 安裝依賴項

安裝專案級的依賴項：

```bash
pnpm install
```

## 2. 構建和打包應用

要構建 macOS 應用並將其打包到 `dist/OpenClaw.app`，執行：

```bash
./scripts/package-mac-app.sh
```

如果您沒有 Apple 開發者 ID 憑證，指令碼會自動使用**臨時簽名** (`-`)。

有關開發執行模式、簽署旗標和團隊 ID 故障排除，請參閱 macOS 應用 README：
[https://github.com/openclaw/openclaw/blob/main/apps/macos/README.md](https://github.com/openclaw/openclaw/blob/main/apps/macos/README.md)

> **注意**：臨時簽署的應用可能會觸發安全提示。如果應用立即因「Abort trap 6」崩潰，請參閱[故障排除](#troubleshooting)部分。

## 3. 安裝 CLI

macOS 應用期望全域 `openclaw` CLI 安裝以管理背景工作。

**安裝方式（建議）：**

1. 開啟 OpenClaw 應用。
2. 前往**一般**設定標籤。
3. 點擊**「安裝 CLI」**。

或者，手動安裝：

```bash
npm install -g openclaw@<version>
```

## 故障排除

### 構建失敗：工具鏈或 SDK 不符

macOS 應用構建期望最新的 macOS SDK 和 Swift 6.2 工具鏈。

**系統依賴項（必須）：**

- **軟體更新中可用的最新 macOS 版本**（Xcode 26.2 SDK 必須）
- **Xcode 26.2**（Swift 6.2 工具鏈）

**檢查：**

```bash
xcodebuild -version
xcrun swift --version
```

如果版本不符，請更新 macOS/Xcode 並重新執行構建。

### 應用在權限授予時崩潰

如果在嘗試允許**語音辨識**或**麥克風**存取時應用崩潰，可能是因為損壞的 TCC 快取或簽名不符。

**修正：**

1. 重設 TCC 權限：

   ```bash
   tccutil reset All ai.openclaw.mac.debug
   ```

2. 如果失敗，暫時更改 [`scripts/package-mac-app.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/package-mac-app.sh) 中的 `BUNDLE_ID` 以從 macOS 強制「乾淨樓梯」。

### 閘道「啟動中...」無限期

如果閘道狀態保留在「啟動中...」，請檢查是否有殭屍處理程序佔據該埠：

```bash
openclaw gateway status
openclaw gateway stop

# 如果您未使用 LaunchAgent（開發模式/手動執行），找到監聽程式：
lsof -nP -iTCP:18789 -sTCP:LISTEN
```

如果手動執行佔據該埠，停止該處理程序 (Ctrl+C)。作為最後的手段，終止您上面找到的 PID。
