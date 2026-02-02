---
title: "發布檢查清單"
summary: "npm + macOS App 的逐步發布檢查清單"
read_when:
  - 發布新的 npm 版本時
  - 發布新的 macOS App 版本時
  - 發布前驗證中繼資料時
---

# 發布檢查清單（npm + macOS）

從 Repo 根目錄使用 `pnpm`（Node 22+）。在標籤/發布前保持工作樹乾淨。

## 操作員觸發

當操作員說「release」時，立即執行此起飛前檢查（除非被阻止，否則無需額外問題）：

- 讀取本文件和 `docs/platforms/mac/release.md`。
- 從 `~/.profile` 載入 env 並確認 `SPARKLE_PRIVATE_KEY_FILE` + App Store Connect 變數已設定（SPARKLE_PRIVATE_KEY_FILE 應位於 `~/.profile`）。
- 若需要，使用 `~/Library/CloudStorage/Dropbox/Backup/Sparkle` 中的 Sparkle 金鑰。

1. **版本與中繼資料**

- [ ] 凸版 `package.json` 版本（例如 `2026.1.29`）。
- [ ] 執行 `pnpm plugins:sync` 對齊擴充套件套件版本 + 變更日誌。
- [ ] 更新 CLI/版本字串：[`src/cli/program.ts`](https://github.com/openclaw/openclaw/blob/main/src/cli/program.ts) 和 [`src/provider-web.ts`](https://github.com/openclaw/openclaw/blob/main/src/provider-web.ts) 中的 Baileys 使用者代理。
- [ ] 確認套件中繼資料（name、description、repository、keywords、license）且 `bin` 對應指向 [`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs) 用於 `openclaw`。
- [ ] 若相依性變更，執行 `pnpm install` 使 `pnpm-lock.yaml` 為目前版本。

2. **建置 & 產物**

- [ ] 若 A2UI 輸入變更，執行 `pnpm canvas:a2ui:bundle` 並提交任何更新的 [`src/canvas-host/a2ui/a2ui.bundle.js`](https://github.com/openclaw/openclaw/blob/main/src/canvas-host/a2ui/a2ui.bundle.js)。
- [ ] `pnpm run build`（重新生成 `dist/`）。
- [ ] 驗證 npm 套件 `files` 包含所有必要的 `dist/*` 資料夾（特別是 `dist/node-host/**` 和 `dist/acp/**` 用於無頭節點 + ACP CLI）。
- [ ] 確認 `dist/build-info.json` 存在且包含預期的 `commit` 雜湊（CLI 橫幅在 npm 安裝時使用此項）。
- [ ] 選用：建置後執行 `npm pack --pack-destination /tmp`；檢查 tarball 內容並保留用於 GitHub 發布（**不**提交）。

3. **變更日誌 & 文件**

- [ ] 用使用者面向的亮點更新 `CHANGELOG.md`（如不存在則建立檔案）；保持項目嚴格按版本降序。
- [ ] 確保 README 範例/旗標符合目前 CLI 行為（特別是新指令或選項）。

4. **驗證**

- [ ] `pnpm build`
- [ ] `pnpm check`
- [ ] `pnpm test`（或 `pnpm test:coverage` 若需覆蓋輸出）
- [ ] `pnpm release:check`（驗證 npm pack 內容）
- [ ] `OPENCLAW_INSTALL_SMOKE_SKIP_NONROOT=1 pnpm test:install:smoke`（Docker 安裝煙霧測試，快速路徑；發布前需要）
  - 若前一次 npm 發布已知損壞，設定 `OPENCLAW_INSTALL_SMOKE_PREVIOUS=<last-good-version>` 或 `OPENCLAW_INSTALL_SMOKE_SKIP_PREVIOUS=1` 用於預安裝步驟。
- [ ] （選用）完整安裝程式煙霧（新增非根 + CLI 覆蓋）：`pnpm test:install:smoke`
- [ ] （選用）安裝程式 E2E（Docker，執行 `curl -fsSL https://openclaw.ai/install.sh | bash`，上線，接著執行實際工具呼叫）：
  - `pnpm test:install:e2e:openai`（需要 `OPENAI_API_KEY`）
  - `pnpm test:install:e2e:anthropic`（需要 `ANTHROPIC_API_KEY`）
  - `pnpm test:install:e2e`（需要兩個金鑰；執行兩個提供者）
- [ ] （選用）若您的變更影響發送/接收路徑，抽查網頁 Gateway。

5. **macOS App（Sparkle）**

- [ ] 建置 + 簽署 macOS App，接著 zip 用於發布。
- [ ] 生成 Sparkle appcast（透由 [`scripts/make_appcast.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/make_appcast.sh) 的 HTML 筆記）並更新 `appcast.xml`。
- [ ] 保留 App zip（及選用 dSYM zip）準備附加至 GitHub 發布。
- [ ] 遵循 [macOS release](/platforms/mac/release) 以取得確切指令和必要 env 變數。
  - `APP_BUILD` 必須是數字 + 單調（無 `-beta`）以使 Sparkle 正確比較版本。
  - 若公證，使用從 App Store Connect API env 變數建立的 `openclaw-notary` 鑰匙圈設定檔（見 [macOS release](/platforms/mac/release)）。

6. **發布（npm）**

- [ ] 確認 git 狀態乾淨；需要時提交並推送。
- [ ] 若需要 `npm login`（驗證 2FA）。
- [ ] `npm publish --access public`（預發布使用 `--tag beta`）。
- [ ] 驗證登錄：`npm view openclaw version`、`npm view openclaw dist-tags` 和 `npx -y openclaw@X.Y.Z --version`（或 `--help`）。

### 疑難排解（來自 2.0.0-beta2 發布的筆記）

- **npm pack/publish 掛起或產生巨大 tarball**：`dist/OpenClaw.app` 中的 macOS App 組合包（及發布 zip）被掃入套件。透由 `package.json` `files` 白名單發布內容來修正（包含 dist 子目錄、文件、技能；排除 App 組合包）。使用 `npm pack --dry-run` 確認 `dist/OpenClaw.app` 未列出。
- **npm auth web 迴圈用於 dist-tags**：使用舊版認證以取得 OTP 提示：
  - `NPM_CONFIG_AUTH_TYPE=legacy npm dist-tag add openclaw@X.Y.Z latest`
- **`npx` 驗證失敗搭配 `ECOMPROMISED: Lock compromised`**：使用新 cache 重試：
  - `NPM_CONFIG_CACHE=/tmp/npm-cache-$(date +%s) npx -y openclaw@X.Y.Z --version`
- **標籤在後期修正後需要重新指向**：強制更新並推送標籤，接著確保 GitHub 發布資產仍符合：
  - `git tag -f vX.Y.Z && git push -f origin vX.Y.Z`

7. **GitHub 發布 + appcast**

- [ ] 標籤並推送：`git tag vX.Y.Z && git push origin vX.Y.Z`（或 `git push --tags`）。
- [ ] 為 `vX.Y.Z` 建立/重新整理 GitHub 發布，**標題為 `openclaw X.Y.Z`**（非只是標籤）；主體應包含該版本的**完整**變更日誌段落（亮點 + 變更 + 修正），內連（無裸露連結），且**不得在主體內重複標題**。
- [ ] 附加產物：`npm pack` tarball（選用）、`OpenClaw-X.Y.Z.zip` 和 `OpenClaw-X.Y.Z.dSYM.zip`（若已生成）。
- [ ] 提交更新的 `appcast.xml` 並推送它（Sparkle 從 main 供給）。
- [ ] 從乾淨暫存目錄（無 `package.json`），執行 `npx -y openclaw@X.Y.Z send --help` 確認安裝/CLI 進入點有效。
- [ ] 公告/分享發布筆記。

## 外掛發布範圍（npm）

我們僅在 `@openclaw/*` 範圍下發布**現有 npm 外掛**。未在 npm 上的組合外掛保持**僅限磁碟樹**（仍在 `extensions/**` 中發運）。

衍生清單的流程：

1. `npm search @openclaw --json` 並擷取套件名稱。
2. 與 `extensions/*/package.json` 名稱比較。
3. 僅發布**交集**（已在 npm 上）。

目前 npm 外掛清單（更新如需）：

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

發布筆記也必須呼叫**非預設啟用**的**新選用組合外掛**（範例：`tlon`）。
