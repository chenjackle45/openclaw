---
title: "Bun (Experimental)（實驗性）"
summary: "Bun 工作流（實驗性）：安裝和與 pnpm 比較的已知問題"
read_when:
  - 您想要最快的本地開發迴圈 (bun + watch)
  - 您遇到 Bun 安裝/patch/生命週期腳本問題
---

# Bun (實驗性)

目標：使用 **Bun** 執行此儲存庫（可選，不推薦 WhatsApp/Telegram）
而無需與 pnpm 工作流分歧。

⚠️ **不推薦用於 Gateway 執行時**（WhatsApp/Telegram 錯誤）。生產使用 Node。

## 狀態

- Bun 是可選的本地執行時，用於直接執行 TypeScript（`bun run …`、`bun --watch …`）。
- `pnpm` 是構建的預設值，完全支援（某些文件工具使用）。
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

## 構建 / 測試（Bun）

```sh
bun run build
bun run vitest run
```

## Bun 生命週期指令碼（預設被阻止）

Bun 可能阻止依賴生命週期指令碼，除非明確信任（`bun pm untrusted` / `bun pm trust`）。
對於此儲存庫，通常阻止的指令碼不是必需的：

- `@whiskeysockets/baileys` `preinstall`：檢查 Node major >= 20（我們執行 Node 22+）。
- `protobufjs` `postinstall`：發出有關不相容版本方案的警告（無構建產物）。

如果遇到需要這些指令碼的實際執行時問題，明確信任：

```sh
bun pm trust @whiskeysockets/baileys protobufjs
```

## 注意事項

- 某些指令碼仍然硬編碼 pnpm（例如 `docs:build`、`ui:*`、`protocol:check`）。現在通過 pnpm 執行這些。
