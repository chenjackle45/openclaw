# Auth Credential Semantics（驗證憑證語義）

本文定義在以下範圍使用的正式憑證資格與解析語義：

- `resolveAuthProfileOrder`
- `resolveApiKeyForProfile`
- `models status --probe`
- `doctor-auth`

目標是保持選擇時和執行階段行為的一致性。

## 穩定原因代碼

- `ok`
- `missing_credential`
- `invalid_expires`
- `expired`
- `unresolved_ref`

## Token 憑證

Token 憑證（`type: "token"`）支援內嵌的 `token` 和／或 `tokenRef`。

### 資格規則

1. 當 `token` 和 `tokenRef` 都缺失時，token profile 不符合資格。
2. `expires` 是選用的。
3. 若 `expires` 存在，它必須是大於 `0` 的有限數字。
4. 若 `expires` 無效（`NaN`、`0`、負數、非有限數，或類型錯誤），profile 不符合資格，原因為 `invalid_expires`。
5. 若 `expires` 已過期，profile 不符合資格，原因為 `expired`。
6. `tokenRef` 不會繞過 `expires` 驗證。

### 解析規則

1. 解析器語義與 `expires` 的資格語義一致。
2. 對於符合資格的 profile，token 材料可從內嵌值或 `tokenRef` 解析。
3. 無法解析的 ref 在 `models status --probe` 輸出中產生 `unresolved_ref`。

## 舊版相容訊息

為了腳本相容性，探測錯誤的第一行保持不變：

`Auth profile credentials are missing or expired.`

人類友善的詳情和穩定原因代碼可在後續行中添加。
