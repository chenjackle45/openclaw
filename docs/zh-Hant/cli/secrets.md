---
summary: "`openclaw secrets` CLI 參考（重新載入、稽核、配置、套用）"
read_when:
  - 在執行時重新解析 secret refs 時
  - 稽核明文殘留和未解析的 refs 時
  - 配置 SecretRefs 並套用單向清除變更時
title: "secrets（Secret 管理）"
---

# `openclaw secrets`

使用 `openclaw secrets` 管理 SecretRefs 並保持目前執行時快照的健康狀態。

指令角色：

- `reload`：Gateway RPC（`secrets.reload`），重新解析 refs 並僅在完全成功時交換執行時快照（不寫入 config）。
- `audit`：對 configuration/auth/generated-model 儲存和傳統殘留進行唯讀掃描，檢查明文、未解析 refs 和優先順序漂移。
- `configure`：供應商設定、目標映射和預檢的互動式規劃工具（需要 TTY）。
- `apply`：執行已儲存的計畫（`--dry-run` 僅用於驗證），然後清除目標的明文殘留。

建議的操作員流程：

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets audit --check
openclaw secrets reload
```

CI/gates 的退出碼注意事項：

- `audit --check` 在有發現時返回 `1`。
- 未解析的 refs 返回 `2`。

相關資訊：

- Secrets 指南：[Secrets Management](/zh-Hant/gateway/secrets)
- 憑證介面：[SecretRef Credential Surface](/zh-Hant/reference/secretref-credential-surface)
- 安全性指南：[Security](/zh-Hant/gateway/security)

## 重新載入執行時快照

重新解析 secret refs 並以原子方式交換執行時快照。

```bash
openclaw secrets reload
openclaw secrets reload --json
```

注意事項：

- 使用 Gateway RPC 方法 `secrets.reload`。
- 若解析失敗，gateway 保持最後已知的良好快照並返回錯誤（不進行部分啟動）。
- JSON 回應包含 `warningCount`。

## 稽核

掃描 OpenClaw 狀態以找出：

- 明文密鑰儲存
- 未解析的 refs
- 優先順序漂移（`auth-profiles.json` 憑證遮蔽 `openclaw.json` refs）
- 生成的 `agents/*/agent/models.json` 殘留（供應商 `apiKey` 值和敏感供應商標頭）
- 傳統殘留（傳統 auth 儲存條目、OAuth 提醒）

標頭殘留注意事項：

- 敏感供應商標頭偵測是基於名稱啟發式（常見的 auth/credential 標頭名稱和片段，如 `authorization`、`x-api-key`、`token`、`secret`、`password` 和 `credential`）。

```bash
openclaw secrets audit
openclaw secrets audit --check
openclaw secrets audit --json
```

退出行為：

- `--check` 在有發現時以非零狀態退出。
- 未解析的 refs 以更高優先順序的非零碼退出。

報告結構重點：

- `status`：`clean | findings | unresolved`
- `summary`：`plaintextCount`、`unresolvedRefCount`、`shadowedRefCount`、`legacyResidueCount`
- 發現碼：
  - `PLAINTEXT_FOUND`
  - `REF_UNRESOLVED`
  - `REF_SHADOWED`
  - `LEGACY_RESIDUE`

## 配置（互動式輔助工具）

互動式建立供應商和 SecretRef 變更、執行預檢，以及可選地套用：

```bash
openclaw secrets configure
openclaw secrets configure --plan-out /tmp/openclaw-secrets-plan.json
openclaw secrets configure --apply --yes
openclaw secrets configure --providers-only
openclaw secrets configure --skip-provider-setup
openclaw secrets configure --agent ops
openclaw secrets configure --json
```

流程：

- 首先供應商設定（對 `secrets.providers` 別名進行 `add/edit/remove`）。
- 其次憑證映射（選擇欄位並指派 `{source, provider, id}` refs）。
- 最後預檢和可選的套用。

旗標：

- `--providers-only`：僅配置 `secrets.providers`，跳過憑證映射。
- `--skip-provider-setup`：跳過供應商設定，將憑證映射至現有供應商。
- `--agent <id>`：將 `auth-profiles.json` 目標探索和寫入限定至單一 agent 儲存。

注意事項：

- 需要互動式 TTY。
- 不能將 `--providers-only` 與 `--skip-provider-setup` 組合使用。
- `configure` 目標包含 `openclaw.json` 和所選 agent 範圍的 `auth-profiles.json` 中的含密鑰欄位。
- `configure` 支援直接在選擇器流程中建立新的 `auth-profiles.json` 映射。
- 規範支援介面：[SecretRef Credential Surface](/zh-Hant/reference/secretref-credential-surface)。
- 在套用前執行預檢解析。
- 生成的計畫預設使用清除選項（`scrubEnv`、`scrubAuthProfilesForProviderTargets`、`scrubLegacyAuthJson` 均啟用）。
- 套用路徑對已清除的明文值是單向的。
- 若未使用 `--apply`，CLI 仍會在預檢後提示 `Apply this plan now?`。
- 使用 `--apply`（且未使用 `--yes`）時，CLI 會提示額外的不可逆確認。

exec 供應商安全注意事項：

- Homebrew 安裝通常在 `/opt/homebrew/bin/*` 下暴露符號連結的二進位檔案。
- 僅在受信任的套件管理器路徑需要時設定 `allowSymlinkCommand: true`，並搭配 `trustedDirs`（例如 `["/opt/homebrew"]`）。
- 在 Windows 上，若供應商路徑的 ACL 驗證無法使用，OpenClaw 會快速失敗。僅對受信任的路徑設定 `allowInsecurePath: true` 以繞過路徑安全檢查。

## 套用已儲存的計畫

套用或預檢先前生成的計畫：

```bash
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --json
```

計畫規範細節（允許的目標路徑、驗證規則和失敗語意）：

- [Secrets Apply Plan Contract](/zh-Hant/gateway/secrets-plan-contract)

`apply` 可能更新的內容：

- `openclaw.json`（SecretRef 目標 + 供應商 upserts/deletes）
- `auth-profiles.json`（供應商目標清除）
- 傳統的 `auth.json` 殘留
- `~/.openclaw/.env` 中值已遷移的已知密鑰鍵

## 為何不提供回滾備份

`secrets apply` 有意不寫入包含舊明文值的回滾備份。

安全性來自嚴格的預檢 + 原子式套用，失敗時進行最佳努力的記憶體還原。

## 範例

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets audit --check
```

若 `audit --check` 仍報告明文發現，請更新其餘報告的目標路徑並重新執行稽核。
