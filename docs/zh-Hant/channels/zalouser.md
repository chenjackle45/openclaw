---
title: "Zalouser(Zalo 個人帳號)"
summary: "透過 zca-cli (QR 登入) 的 Zalo 個人帳號支援、功能與設定"
read_when:
  - 為 OpenClaw 設定 Zalo 個人帳號時
  - 偵錯 Zalo 個人帳號登入或訊息流程時
---
# Zalo 個人帳號 (非官方插件)

狀態：實驗性功能。此整合透過 `zca-cli` 自動化操作 **Zalo 個人帳號**。

> [!WARNING]
> **警告**：這是一個非官方的整合方式，可能會導致帳號被停權或封禁。請自行承擔使用風險。

## 安裝插件
此插件不隨核心程式綑綁，需單獨安裝：
```bash
openclaw plugins install @openclaw/zalouser
```

## 先決條件：zca-cli
Gateway 機器必須在 `PATH` 中載有 `zca` 執行檔。請確認 `zca --version` 可以正常執行。

## 快速設定（初學者）
1. 安裝插件。
2. 登入（在 Gateway 機器上掃描 QR 碼）：
   - 執行 `openclaw channels login --channel zalouser`。
   - 使用 Zalo 手機 App 掃描終端機顯示的 QR 碼。
3. 在設定中啟用頻道。
4. 重啟 Gateway。
5. 私訊存取預設為配對模式，初次聯繫時請核准配對碼。

## 功能說明
- 使用 `zca listen` 接收訊息，並使用 `zca msg` 發送文字、媒體或連結回覆。
- 專為無法獲得 Zalo Bot API 授權的個人帳號需求設計。
- **命名區分**：為明確起見，ID 設為 `zalouser` 以區分官方的 `zalo` 機器人 API。

## 存取控制
- **私訊**：支援配對 (`pairing`)、允許清單 (`allowlist`)、開放 (`open`) 或停用 (`disabled`)。
- **群組**：支援設定房間允許清單。

## 限制
- 出站文字每塊上限約 **2000 字元**。
- 預設停用串流回應。

## 故障排除
- **找不到 `zca`**：請確認 zca-cli 已正確安裝於 Gateway 程序的 `PATH` 環境變數中。
- **登入狀態失效**：嘗試先執行 `logout` 再重新啟動 `login` 流程。
