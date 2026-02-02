---
title: "Bun (實驗性)"
summary: "Bun 工作流程（實驗性）：安裝與相比 pnpm 之相關須知"
read_when:
  - 您想要最快的本地開發迴圈 (bun + watch)
  - 您遇到 Bun 安裝/patch/生命週期腳本問題
---

# Bun (實驗性)

目標：在不偏離 pnpm 工作流程的前提下，用 **Bun** 執行此儲存庫（選用，不建議用於 WhatsApp/Telegram）。

⚠️ **不建議用於 Gateway 生產環境**（WhatsApp/Telegram bug）。生產環境請使用 Node。

## 狀態

- Bun 是可選的本地執行環境，用於直接執行 TypeScript（`bun run …`、`bun --watch …`）。
- `pnpm` 是建置預設，保持完整支援（部分文件工具組亦使用）。
- Bun 無法使用 `pnpm-lock.yaml` 且將其忽略。

## 安裝

預設：

```sh
bun install
```

注意：`bun.lock`/`bun.lockb` 已加入 gitignore，因此無論如何都不會產生 repo 變動。若不想寫入鎖定檔：

```sh
bun install --no-save
```

## 建置 / 測試 (Bun)

```sh
bun run build
bun run vitest run
```

## Bun 生命週期腳本（預設阻止）

Bun 可能會阻止依賴的生命週期腳本，除非明確信任（`bun pm untrusted` / `bun pm trust`）。
此儲存庫中通常被阻止的腳本並非必須：

- `@whiskeysockets/baileys` `preinstall`：檢查 Node major >= 20（我們執行 Node 22+）。
- `protobufjs` `postinstall`：發出版本不相容警告（無建置產出物）。

若遇到真正的執行期問題需要這些腳本，明確信任它們：

```sh
bun pm trust @whiskeysockets/baileys protobufjs
```

## 注意事項

- 部分腳本仍硬編碼 pnpm（例如 `docs:build`、`ui:*`、`protocol:check`）。目前請透過 pnpm 執行。
