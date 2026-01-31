---
title: "RELEASING(發布檢查清單)"
summary: "npm + macOS App 的逐步發布檢查清單"
read_when:
  - 發布新的 npm 版本
  - 發布新的 macOS App 版本
  - 在發布前驗證 Metadata
---

# 發布檢查清單 (npm + macOS)

從 Repo Root 使用 `pnpm`（Node 22+）。在 Tagging/Publishing 前保持 Working Tree 乾淨。

## Operator 觸發
當 Operator 說「release」時，立即執行此預檢（除非被阻塞，否則不需額外問題）：
- 閱讀本文件和 `docs/platforms/mac/release.md`。
- 從 `~/.profile` 載入 Env 並確認 `SPARKLE_PRIVATE_KEY_FILE` + App Store Connect 變數已設定（SPARKLE_PRIVATE_KEY_FILE 應位於 `~/.profile`）。
- 如需要，使用 `~/Library/CloudStorage/Dropbox/Backup/Sparkle` 中的 Sparkle Keys。

1) **版本 & Metadata**
- [ ] 更新 `package.json` 版本（例如 `2026.1.29`）。
- [ ] 執行 `pnpm plugins:sync` 以對齊 Extension Package 版本 + Changelogs。
- [ ] 更新 CLI/Version 字串：[`src/cli/program.ts`](https://github.com/openclaw/openclaw/blob/main/src/cli/program.ts) 和 [`src/provider-web.ts`](https://github.com/openclaw/openclaw/blob/main/src/provider-web.ts) 中的 Baileys User Agent。
- [ ] 確認 Package Metadata（name、description、repository、keywords、license）且 `bin` Map 指向 [`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs) 作為 `openclaw`。
- [ ] 如果 Dependencies 變更，執行 `pnpm install` 讓 `pnpm-lock.yaml` 是最新的。

2) **Build & Artifacts**
- [ ] 如果 A2UI Inputs 變更，執行 `pnpm canvas:a2ui:bundle` 並 Commit 任何更新的 [`src/canvas-host/a2ui/a2ui.bundle.js`](https://github.com/openclaw/openclaw/blob/main/src/canvas-host/a2ui/a2ui.bundle.js)。
- [ ] `pnpm run build`（重新生成 `dist/`）。
- [ ] 驗證 npm Package `files` 包含所有必要的 `dist/*` 資料夾（特別是 `dist/node-host/**` 和 `dist/acp/**` 用於 Headless Node + ACP CLI）。
- [ ] 確認 `dist/build-info.json` 存在且包含預期的 `commit` Hash（CLI Banner 在 npm 安裝時使用此項）。
- [ ] 可選：Build 後執行 `npm pack --pack-destination /tmp`；檢查 Tarball 內容並保留給 GitHub Release（**不要** Commit 它）。

3) **Changelog & Docs**
- [ ] 使用 User-facing Highlights 更新 `CHANGELOG.md`（如不存在則建立檔案）；保持 Entries 嚴格依版本降序。
- [ ] 確保 README 範例/Flags 與目前 CLI 行為相符（特別是新指令或選項）。

4) **驗證**
- [ ] `pnpm lint`
- [ ] `pnpm test`（或 `pnpm test:coverage` 如需 Coverage 輸出）
- [ ] `pnpm run build`（測試後的最後 Sanity Check）
- [ ] `pnpm release:check`（驗證 npm Pack 內容）
- [ ] `OPENCLAW_INSTALL_SMOKE_SKIP_NONROOT=1 pnpm test:install:smoke`（Docker 安裝 Smoke Test，快速路徑；發布前必須）
  - 如果前一個 npm 發布已知損壞，請設定 `OPENCLAW_INSTALL_SMOKE_PREVIOUS=<last-good-version>` 或 `OPENCLAW_INSTALL_SMOKE_SKIP_PREVIOUS=1` 用於 Preinstall 步驟。
- [ ]（可選）完整 Installer Smoke（新增 Non-root + CLI Coverage）：`pnpm test:install:smoke`
- [ ]（可選）Installer E2E（Docker，執行 `curl -fsSL https://openclaw.bot/install.sh | bash`，Onboard，然後執行真實 Tool Calls）：
  - `pnpm test:install:e2e:openai`（需要 `OPENAI_API_KEY`）
  - `pnpm test:install:e2e:anthropic`（需要 `ANTHROPIC_API_KEY`）
  - `pnpm test:install:e2e`（需要兩個 Keys；執行兩個 Providers）
- [ ]（可選）如果您的變更影響 Send/Receive 路徑，Spot-check Web Gateway。

5) **macOS App (Sparkle)**
- [ ] Build + Sign macOS App，然後 Zip 作為發布。
- [ ] 生成 Sparkle Appcast（透過 [`scripts/make_appcast.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/make_appcast.sh) 的 HTML Notes）並更新 `appcast.xml`。
- [ ] 保留 App Zip（和可選的 dSYM Zip）準備附加到 GitHub Release。
- [ ] 遵循 [macOS release](/platforms/mac/release) 了解確切指令和必要 Env Vars。
  - `APP_BUILD` 必須是 Numeric + Monotonic（無 `-beta`）讓 Sparkle 正確比較版本。
  - 如果 Notarizing，使用從 App Store Connect API Env Vars 建立的 `openclaw-notary` Keychain Profile（見 [macOS release](/platforms/mac/release)）。

6) **發布 (npm)**
- [ ] 確認 Git 狀態乾淨；如需要則 Commit 並 Push。
- [ ] 如需要 `npm login`（驗證 2FA）。
- [ ] `npm publish --access public`（Pre-releases 使用 `--tag beta`）。
- [ ] 驗證 Registry：`npm view openclaw version`、`npm view openclaw dist-tags` 和 `npx -y openclaw@X.Y.Z --version`（或 `--help`）。

### 疑難排解（來自 2.0.0-beta2 Release 的筆記）
- **npm pack/publish 卡住或產生巨大 Tarball**：`dist/OpenClaw.app` 中的 macOS App Bundle（和 Release Zips）被掃入 Package。透過 `package.json` `files` Whitelist 發布內容來修正（包含 Dist Subdirs、Docs、Skills；排除 App Bundles）。使用 `npm pack --dry-run` 確認 `dist/OpenClaw.app` 未列出。
- **npm Auth Web Loop for dist-tags**：使用 Legacy Auth 取得 OTP Prompt：
  - `NPM_CONFIG_AUTH_TYPE=legacy npm dist-tag add openclaw@X.Y.Z latest`
- **`npx` 驗證失敗並顯示 `ECOMPROMISED: Lock compromised`**：使用新 Cache 重試：
  - `NPM_CONFIG_CACHE=/tmp/npm-cache-$(date +%s) npx -y openclaw@X.Y.Z --version`
- **Tag 在後期修復後需要重新指向**：Force-update 並 Push Tag，然後確保 GitHub Release Assets 仍相符：
  - `git tag -f vX.Y.Z && git push -f origin vX.Y.Z`

7) **GitHub Release + Appcast**
- [ ] Tag 並 Push：`git tag vX.Y.Z && git push origin vX.Y.Z`（或 `git push --tags`）。
- [ ] 為 `vX.Y.Z` 建立/重新整理 GitHub Release，**標題為 `openclaw X.Y.Z`**（不只是 Tag）；Body 應包含該版本的**完整** Changelog 段落（Highlights + Changes + Fixes），Inline（無 Bare Links），且**不得在 Body 內重複標題**。
- [ ] 附加 Artifacts：`npm pack` Tarball（可選）、`OpenClaw-X.Y.Z.zip` 和 `OpenClaw-X.Y.Z.dSYM.zip`（如已生成）。
- [ ] Commit 更新的 `appcast.xml` 並 Push 它（Sparkle 從 Main Feed）。
- [ ] 從乾淨的 Temp 目錄（無 `package.json`），執行 `npx -y openclaw@X.Y.Z send --help` 確認 Install/CLI Entrypoints 運作。
- [ ] 公告/分享 Release Notes。

## Plugin 發布範圍 (npm)

我們只在 `@openclaw/*` Scope 下發布**現有 npm Plugins**。未在 npm 上的 Bundled Plugins 保持**僅 Disk-tree**（仍在 `extensions/**` 中提供）。

衍生清單的流程：
1) `npm search @openclaw --json` 並擷取 Package 名稱。
2) 與 `extensions/*/package.json` 名稱比較。
3) 僅發布**交集**（已在 npm 上）。

目前 npm Plugin 清單（如需更新）：
- @openclaw/bluebubbles
- @openclaw/diagnostics-otel
- @openclaw/discord
- @openclaw/lobster
- @openclaw/matrix
- @openclaw/msteams
- @openclaw/nextcloud-talk
- @openclaw/nostr
- @openclaw/voice-call
- @openclaw/zalo
- @openclaw/zalouser

Release Notes 也必須提出**非預設啟用**的**新選用 Bundled Plugins**（例如：`tlon`）。
