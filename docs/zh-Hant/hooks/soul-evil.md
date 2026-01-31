---
title: "Soul evil(SOUL Evil Hook)"
summary: "SOUL Evil hook（將 SOUL.md 替換為 SOUL_EVIL.md）"
read_when:
  - 您想要啟用或調整 SOUL Evil hook
  - 您想要設定清除視窗或隨機機率的人格交換
---

# SOUL Evil Hook

SOUL Evil hook 在清除視窗期間或透過隨機機率將**注入的** `SOUL.md` 內容替換為 `SOUL_EVIL.md`。它**不會**修改磁碟上的檔案。

## 運作方式

當 `agent:bootstrap` 執行時，hook 可以在組裝系統提示詞之前在記憶體中替換 `SOUL.md` 內容。如果 `SOUL_EVIL.md` 缺少或為空，OpenClaw 會記錄警告並保留正常的 `SOUL.md`。

Sub-agent 執行**不**在其 bootstrap 檔案中包含 `SOUL.md`，因此此 hook 對 sub-agents 沒有影響。

## 啟用

```bash
openclaw hooks enable soul-evil
```

然後設定配置：

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "soul-evil": {
          "enabled": true,
          "file": "SOUL_EVIL.md",
          "chance": 0.1,
          "purge": { "at": "21:00", "duration": "15m" }
        }
      }
    }
  }
}
```

在代理工作區根目錄（`SOUL.md` 旁邊）建立 `SOUL_EVIL.md`。

## 選項

- `file`（字串）：替代 SOUL 檔案名稱（預設：`SOUL_EVIL.md`）
- `chance`（數字 0–1）：每次執行使用 `SOUL_EVIL.md` 的隨機機率
- `purge.at` (HH:mm)：每日清除開始時間（24 小時制）
- `purge.duration`（duration）：視窗長度（例如 `30s`、`10m`、`1h`）

**優先順序：**清除視窗優先於機率。

**時區：**設定時使用 `agents.defaults.userTimezone`；否則使用主機時區。

## 注意事項

- 不會在磁碟上寫入或修改任何檔案。
- 如果 `SOUL.md` 不在 bootstrap 清單中，hook 不會執行任何操作。

## 另請參閱

- [Hooks](/hooks)
