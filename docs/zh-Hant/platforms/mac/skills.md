---
title: "skills(macOS Skills)"
summary: "macOS Skills 設定 UI 與 Gateway 支援的狀態"
read_when:
  - 更新 macOS Skills 設定 UI 時
  - 變更技能 Gating 或安裝行為時
---

# Skills (macOS)

macOS 應用程式透過 Gateway 呈現 OpenClaw Skills；它不會在本地解析 Skills。

## 資料來源

- `skills.status` (Gateway) 回傳所有 Skills 加上資格與缺少的依賴項
  （包含綑綁 Skills 的允許清單阻擋）。
- 需求源自於每個 `SKILL.md` 中的 `metadata.openclaw.requires`。

## 安裝動作

- `metadata.openclaw.install` 定義安裝選項 (brew/node/go/uv)。
- 應用程式呼叫 `skills.install` 在 Gateway 主機上執行安裝程式。
- 當提供多個安裝程式時，Gateway 僅呈現一個偏好的安裝程式
  （若可用則為 brew，否則為來自 `skills.install` 的 node manager，預設為 npm）。

## 環境變數/API 金鑰

- 應用程式將金鑰儲存在 `~/.openclaw/openclaw.json` 的 `skills.entries.<skillKey>` 下。
- `skills.update` 修補 `enabled`, `apiKey`, 以及 `env`。

## Remote 模式

- 安裝 + 設定更新發生在 Gateway 主機上（非本地 Mac）。
