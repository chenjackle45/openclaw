---
summary: "Windows（WSL2）支援 + 伴隨應用程式狀態"
read_when:
  - 在 Windows 上安裝 OpenClaw
  - 尋找 Windows 伴隨應用程式狀態
title: "Windows (WSL2)（Windows WSL2 支援）"
---

# Windows（WSL2）

Windows 上的 OpenClaw 推薦透過 WSL2（推薦 Ubuntu）。
CLI + Gateway 在 Linux 內執行，保持執行時一致並讓
工具更相容（Node/Bun/pnpm、Linux 二進位檔、技能）。原生
Windows 可能更棘手。WSL2 給你完整 Linux 體驗 — 安裝一行指令：wsl --install。

原生 Windows 伴隨應用程式已計畫。

## 安裝 (WSL2)

- [開始使用](/zh-Hant/start/getting-started)（在 WSL 內使用）
- [安裝和更新](/zh-Hant/install/updating)
- 官方 WSL2 指南（Microsoft）：https://learn.microsoft.com/windows/wsl/install

## Gateway

- [Gateway runbook](/zh-Hant/gateway)
- [配置](/zh-Hant/gateway/configuration)

## Gateway 服務安裝 (CLI)

在 WSL2 內：

openclaw onboard --install-daemon

或：

openclaw gateway install

或：

openclaw configure

提示時選擇 Gateway 服務。

修復/遷移：

openclaw doctor

## 進階：透過 LAN 暴露 WSL 服務（portproxy）

WSL 有其自己的虛擬網路。如果另一機器需要到達在 WSL 內執行的服務
（SSH、本機 TTS 伺服器或 Gateway），你必須
將 Windows 連接埠轉送到目前 WSL IP。WSL IP 在重新啟動後變更，
所以你可能需要重新整理轉送規則。

詳見官方 WSL 文件以獲取 portproxy 設定詳節。

## 逐步 WSL2 安裝

### 1) 安裝 WSL2 + Ubuntu

開啟 PowerShell（管理員）：

wsl --install

或明確選擇 distro：

wsl --list --online
wsl --install -d Ubuntu-24.04

如果 Windows 要求，重新開機。

### 2) 啟用 systemd（gateway 安裝必需）

在你的 WSL 終端中，編輯 /etc/wsl.conf 以啟用 systemd。

詳見 WSL 官方文件。

### 3) 安裝 OpenClaw（在 WSL 內）

在 WSL 內按照 Linux 開始使用流程：

git clone https://github.com/openclaw/openclaw.git
cd openclaw
pnpm install
pnpm ui:build
pnpm build
openclaw onboard

完整指南：[開始使用](/zh-Hant/start/getting-started)

## Windows 伴隨應用程式

我們還沒有 Windows 伴隨應用程式。歡迎貢獻。
