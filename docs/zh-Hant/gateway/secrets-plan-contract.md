---
summary: "`secrets apply` 計畫的合約：目標驗證、路徑匹配和 `auth-profiles.json` 目標範圍"
read_when:
  - 產生或檢查 `openclaw secrets apply` 計畫
  - 除錯 `Invalid plan target path` 錯誤
  - 了解目標型別和路徑驗證行為
title: "Secrets Apply Plan Contract（秘密套用計畫合約）"
---

# Secrets 套用計畫合約

此頁定義由 `openclaw secrets apply` 強制的嚴格合約。

如果目標不符合這些規則，套用在變更設定之前會失敗。

## 計畫檔案形狀

`openclaw secrets apply --from <plan.json>` 期望一個計畫目標的 `targets` 陣列：

```json5
{
  version: 1,
  protocolVersion: 1,
  targets: [
    {
      type: "models.providers.apiKey",
      path: "models.providers.openai.apiKey",
      pathSegments: ["models", "providers", "openai", "apiKey"],
      providerId: "openai",
      ref: { source: "env", provider: "default", id: "OPENAI_API_KEY" },
    },
    {
      type: "auth-profiles.api_key.key",
      path: "profiles.openai:default.key",
      pathSegments: ["profiles", "openai:default", "key"],
      agentId: "main",
      ref: { source: "env", provider: "default", id: "OPENAI_API_KEY" },
    },
  ],
}
```

## 支援的目標範圍

計畫目標已接受下列支援的認證路徑：

- [SecretRef 認證介面](/zh-Hant/reference/secretref-credential-surface)

## 目標型別行為

一般規則：

- `target.type` 必須被辨識，並且必須符合正規化的 `target.path` 形狀。

相容性別名仍然被接受以供現有計畫使用：

- `models.providers.apiKey`
- `skills.entries.apiKey`
- `channels.googlechat.serviceAccount`

## 路徑驗證規則

每個目標都使用以下所有內容進行驗證：

- `type` 必須是已辨識的目標型別。
- `path` 必須是非空點路徑。
- `pathSegments` 可以省略。如果提供，它必須正規化為與 `path` 完全相同的路徑。
- 禁止的區段被拒絕：`__proto__`、`prototype`、`constructor`。
- 正規化路徑必須符合目標型別的已註冊路徑形狀。
- 如果設定了 `providerId` 或 `accountId`，它必須與路徑中編碼的 ID 相符。
- `auth-profiles.json` 目標需要 `agentId`。
- 建立新的 `auth-profiles.json` 對應時，包含 `authProfileProvider`。

## 失敗行為

如果目標驗證失敗，套用會以如下錯誤結束：

```text
Invalid plan target path for models.providers.apiKey: models.providers.openai.baseUrl
```

無效計畫不提交任何寫入。

## 運行時和稽核範圍備註

- 僅限參考的 `auth-profiles.json` 項目（`keyRef`/`tokenRef`）包含在運行時解決和稽核覆蓋中。
- `secrets apply` 寫入支援的 `openclaw.json` 目標、支援的 `auth-profiles.json` 目標和選用清除目標。

## 操作員檢查

```bash
# 驗證計畫而不寫入
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run

# 然後真正套用
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
```

如果套用因無效目標路徑訊息而失敗，使用 `openclaw secrets configure` 重新產生計畫或將目標路徑修正為上述支援的形狀。

## 相關文件

- [Secrets 管理](/zh-Hant/gateway/secrets)
- [CLI `secrets`](/zh-Hant/cli/secrets)
- [SecretRef 認證介面](/zh-Hant/reference/secretref-credential-surface)
- [設定參考](/zh-Hant/gateway/configuration-reference)
