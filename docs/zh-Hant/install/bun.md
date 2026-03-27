---
summary: "Bun 工作流程（實驗性）：安裝和相比 pnpm 的陷阱"
read_when:
  - 你想要最快的本機開發迴圈（bun + watch）
  - 你遇到 Bun 安裝/補丁/生命週期腳本問題
title: "Bun (Experimental)（Bun（實驗性））"
---

# Bun（實驗性）

<Warning>
Bun **不建議用於 gateway 執行時**（WhatsApp 和 Telegram 已知問題）。生產環境使用 Node。
</Warning>

Bun 是一個可選的本機執行時，用於直接執行 TypeScript（`bun run ...`、`bun --watch ...`）。預設的套件管理員仍為 `pnpm`，完全支援且由文件工具使用。Bun 無法使用 `pnpm-lock.yaml` 並將忽略它。

## 安裝

<Steps>
  <Step title="安裝相依性">
    ```sh
    bun install
    ```

    `bun.lock` / `bun.lockb` 被 gitignored，所以沒有倉庫混亂。若要完全跳過鎖定檔案寫入：

    ```sh
    bun install --no-save
    ```

  </Step>
  <Step title="建置和測試">
    ```sh
    bun run build
    bun run vitest run
    ```
  </Step>
</Steps>

## 生命週期腳本

Bun 會阻止依賴生命週期腳本，除非明確信任。對於此倉庫，通常被阻止的腳本不是必需的：

- `@whiskeysockets/baileys` `preinstall` -- 檢查 Node major >= 20（OpenClaw 預設使用 Node 24，仍然支援 Node 22 LTS，目前 `22.16+`）
- `protobufjs` `postinstall` -- 發出關於不相容版本架構的警告（無建置成品）

如果你遇到執行時期問題需要這些腳本，明確信任它們：

```sh
bun pm trust @whiskeysockets/baileys protobufjs
```

## 警告

某些腳本仍然硬編碼 pnpm（例如 `docs:build`、`ui:*`、`protocol:check`）。目前請通過 pnpm 執行這些。
