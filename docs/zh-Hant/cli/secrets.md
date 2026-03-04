---
summary: "CLI 參考用於 `openclaw secrets`（重新載入、稽核、設定、套用）"
read_when:
  - 在執行時重新解析密鑰參考
  - 稽核明文殘留和未解析的參考
  - 設定 SecretRef 並套用單向清理變更
title: "secrets"
---

# `openclaw secrets`

使用 `openclaw secrets` 管理 SecretRef 並保持活動執行時快照健康。

命令角色：

- `reload`：Gateway RPC（`secrets.reload`），重新解析參考並僅在完全成功時交換執行時快照（無設定寫入）。
- `audit`：設定/身份驗證儲存和舊版殘留的唯讀掃描，用於明文、未解析參考和優先順序偏差。
- `configure`：提供者設定、目標對應和預檢的互動式規劃工具（需要 TTY）。
- `apply`：執行儲存的計畫（`--dry-run` 僅用於驗證），然後清理針對的明文殘留。

建議的操作員循環：

```bash
openclaw secrets audit --check
openclaw secrets configure
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json --dry-run
openclaw secrets apply --from /tmp/openclaw-secrets-plan.json
openclaw secrets audit --check
openclaw secrets reload
```

CI/門的退出代碼注：

- `audit --check` 在有發現時返回 `1`。
- 未解析的參考返回 `2`。

相關：

- 密鑰指南：[密鑰管理](/zh-Hant/gateway/secrets)
- 認證表面：[SecretRef 認證表面](/zh-Hant/reference/secretref-credential-surface)
- 安全性指南：[安全性](/zh-Hant/gateway/security)

## 重新載入執行時快照

重新解析密鑰參考並原子性交換執行時快照。

```bash
openclaw secrets reload
openclaw secrets reload --json
```

註：

- 使用 Gateway RPC 方法 `secrets.reload`。
- 如果解析失敗，Gateway 保持最後已知良好快照並返回錯誤（無部分啟動）。
- JSON 回應包含 `warningCount`。

## 稽核

掃描 OpenClaw 狀態以取得：

- 明文密鑰儲存
- 未解析的參考
- 優先順序偏差（`auth-profiles.json` 認證陰影 `openclaw.json` 參考）
- 舊版殘留（舊版身份驗證儲存條目、OAuth 提醒）

```bash
openclaw secrets audit
openclaw secrets audit --check
openclaw secrets audit --json
```

退出行為：

- `--check` 在有發現時以非零狀態退出。
- 未解析的參考以更高優先順序的非零代碼退出。

報告形狀突顯：

- `status`：`clean | findings | unresolved`
- `summary`：`plaintextCount`、`unresolvedRefCount`、`shadowedRefCount`、`legacyResidueCount`
- 發現代碼：
  - `PLAINTEXT_FOUND`
  - `REF_UNRESOLVED`
  - `REF_SHADOWED`
  - `LEGACY_RESIDUE`

## 設定（互動式助手）

互動式建立提供者和 SecretRef 變更、執行預檢並選擇性套用：

```bash
openclaw secrets configure
openclaw secrets configure --plan-out /tmp/openclaw-secrets-plan.json
openclaw secrets configure --apply --yes
openclaw secrets configure --providers-only
openclaw secrets configure --skip-provider-setup
openclaw secrets configure --agent ops
openclaw secrets configure --json
```
