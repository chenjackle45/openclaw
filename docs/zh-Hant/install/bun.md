---
title: "Bun(實驗性支援)"
summary: "Bun 工作流程：安裝指南與相容性注意事項（相對於 pnpm）"
read_when:
  - 您想要最快的本地開發循環 (bun + watch) 時
  - 您遇到 Bun 安裝、補丁 (patch) 或生命週期腳本問題時
---

# Bun (實驗性支援)

目標：在不偏離 pnpm 工作流程的前提下，使用 **Bun** 執行此倉庫（選用，不建議用於 WhatsApp/Telegram）。

⚠️ **不建議將 Bun 用於 Gateway 生產環境**（已知 WhatsApp/Telegram 存在相應 Bug）。生產環境請使用 Node。

## 現狀

- Bun 是用於直接執行 TypeScript 的選用本地執行期 (Local Runtime)（如 `bun run ...`, `bun --watch ...`）。
- `pnpm` 仍是預設的建置工具，並獲得完整支援（部分文件工具組亦使用 pnpm）。
- Bun 無法讀取 `pnpm-lock.yaml` 且會將其忽略。

## 安裝

預設指令：

```sh
bun install
```

注意：`bun.lock`/`bun.lockb` 已被加入 gitignore，因此不會產生額外的 Git 變動。如果您不想產生鎖定檔 (lockfile)：

```sh
bun install --no-save
```

## 建置 / 測試 (Bun)

```sh
bun run build
- bun run vitest run
```

## Bun 生命週期腳本（預設被阻擋）

Bun 可能會阻擋依賴項的生命週期腳本 (Lifecycle scripts)，除非明確信任它們（`bun pm untrusted` / `bun pm trust`）。
對於本專案，通常被阻擋的腳本並非必要：

- `@whiskeysockets/baileys` `preinstall`: 檢查 Node 版本是否 >= 20（我們使用 Node 22+）。
- `protobufjs` `postinstall`: 發出版本不相容的警告（無建置產出）。

如果您遇到確實需要執行這些腳本的執行期問題，請明確信任它們：

```sh
bun pm trust @whiskeysockets/baileys protobufjs
```

## 注意事項

- 部分腳本仍硬編碼使用 pnpm（例如 `docs:build`, `ui:*`, `protocol:check`）。目前請透過 pnpm 執行這些指令。
