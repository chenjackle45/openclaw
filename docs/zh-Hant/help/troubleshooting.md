---
title: "Troubleshooting(疑難排解)"
summary: "疑難排解中心：症狀 → 檢查 → 修復"
read_when:
  - 您看到錯誤並想要修復路徑時
  - 安裝程式顯示「成功」但 CLI 無法運作時
---

# Troubleshooting(疑難排解)

## 前 60 秒

依序執行以下指令：

```bash
openclaw status
openclaw status --all
openclaw gateway probe
openclaw logs --follow
openclaw doctor
```

如果 Gateway 可連線，執行深度探測：

```bash
openclaw status --deep
```

## 常見「壞掉了」的情況

### `openclaw: command not found`

幾乎總是 Node/npm PATH 問題。從這裡開始：

- [Install (Node/npm PATH 健全性)](/install#nodejs--npm-path-sanity)

### 安裝程式失敗（或您需要完整日誌）

以詳細模式重新執行安裝程式以查看完整追蹤和 npm 輸出：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --verbose
```

Beta 版安裝：

```bash
curl -fsSL https://openclaw.bot/install.sh | bash -s -- --beta --verbose
```

您也可以設定 `OPENCLAW_VERBOSE=1` 來代替旗標。

### Gateway「未授權」、無法連線或持續重新連線

- [Gateway 疑難排解](/gateway/troubleshooting)
- [Gateway 認證](/gateway/authentication)

### Control UI 在 HTTP 上失敗（需要裝置身份）

- [Gateway 疑難排解](/gateway/troubleshooting)
- [Control UI](/web/control-ui#insecure-http)

### `docs.openclaw.ai` 顯示 SSL 錯誤 (Comcast/Xfinity)

某些 Comcast/Xfinity 連線會透過 Xfinity Advanced Security 封鎖 `docs.openclaw.ai`。
停用 Advanced Security 或將 `docs.openclaw.ai` 加入允許清單，然後重試。

- Xfinity Advanced Security 說明：https://www.xfinity.com/support/articles/using-xfinity-xfi-advanced-security
- 快速健全性檢查：嘗試使用行動熱點或 VPN 以確認是 ISP 層級的過濾

### 服務顯示正在運行，但 RPC 探測失敗

- [Gateway 疑難排解](/gateway/troubleshooting)
- [背景程序/服務](/gateway/background-process)

### 模型/認證失敗（速率限制、帳單、「所有模型都失敗」）

- [Models](/cli/models)
- [OAuth / 認證概念](/concepts/oauth)

### `/model` 顯示 `model not allowed`

這通常表示 `agents.defaults.models` 配置為允許清單。當它非空時，
只有那些 provider/model 鍵可以被選擇。

- 檢查允許清單：`openclaw config get agents.defaults.models`
- 新增您想要的模型（或清除允許清單）並重試 `/model`
- 使用 `/models` 瀏覽允許的供應商/模型

### 提交問題時

貼上安全報告：

```bash
openclaw status --all
```

如果可以的話，包含來自 `openclaw logs --follow` 的相關日誌尾部。
