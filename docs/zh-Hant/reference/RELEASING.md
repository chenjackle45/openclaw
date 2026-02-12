---
summary: "npm 和 macOS app 逐步釋放檢查清單"
read_when:
  - 切割新的 npm 釋放
  - 切割新的 macOS app 釋放
  - 發佈前驗證中繼資料
---

# 釋放檢查清單（npm + macOS）

從 repo 根目錄使用 `pnpm`（Node 22+）。在標籤/發佈前保持工作樹潔淨。

## 操作員觸發

當操作員說「釋放」時，立即執行此預檢（除非受阻，否則無額外問題）：

- 讀取此文件和 `docs/platforms/mac/release.md`。
- 從 `~/.profile` 載入環境並確認 `SPARKLE_PRIVATE_KEY_FILE` 和 App Store Connect 變數已設定（SPARKLE_PRIVATE_KEY_FILE 應存在於 `~/.profile`）。
- 如果需要，使用 `~/Library/CloudStorage/Dropbox/Backup/Sparkle` 中的 Sparkle 金鑰。

1. **版本和中繼資料**

- [ ] 更新 `package.json` 版本（例如 `2026.1.29`）。
- [ ] 執行 `pnpm plugins:sync` 以對齊擴充套件套件版本 + 變更記錄。
- [ ] 更新 CLI/版本字串：[`src/cli/program.ts`](https://github.com/openclaw/openclaw/blob/main/src/cli/program.ts) 和 [`src/provider-web.ts`](https://github.com/openclaw/openclaw/blob/main/src/provider-web.ts) 中的 Baileys 使用者代理。
- [ ] 確認套件中繼資料（名稱、描述、儲存庫、關鍵字、授權）和 `bin` 對應指向 [`openclaw.mjs`](https://github.com/openclaw/openclaw/blob/main/openclaw.mjs) 以取得 `openclaw`。
- [ ] 如果依賴項已更改，執行 `pnpm install` 以便 `pnpm-lock.yaml` 是最新的。

2. **建置和成品**

- [ ] 如果 A2UI 輸入已更改，執行 `pnpm canvas:a2ui:bundle` 並認可任何更新的 [`src/canvas-host/a2ui/a2ui.bundle.js`](https://github.com/openclaw/openclaw/blob/main/src/canvas-host/a2ui/a2ui.bundle.js)。
- [ ] `pnpm run build`（重新產生 `dist/`）。
- [ ] 驗證 npm 套件 `files` 包含所有必要的 `dist/*` 資料夾（特別是 `dist/node-host/**` 和 `dist/acp/**` 用於無頭節點 + ACP CLI）。
- [ ] 確認 `dist/build-info.json` 存在並包含預期的 `commit` 雜湊（CLI 橫幅使用此資訊進行 npm 安裝）。
- [ ] 選擇性：在建置後執行 `npm pack --pack-destination /tmp`；檢查 tarball 內容並為 GitHub 釋放保留（**不要**認可）。

3. **變更記錄和文件**

- [ ] 使用面向使用者的重點更新 `CHANGELOG.md`（如果缺失，建立檔案）；按版本嚴格降序保持條目。
- [ ] 確保 README 範例/旗標符合目前 CLI 行為（特別是新命令或選項）。

4. **驗證**

- [ ] `pnpm build`
- [ ] `pnpm check`
- [ ] `pnpm test`（或如果你需要覆蓋輸出，則執行 `pnpm test:coverage`）
- [ ] `pnpm release:check`（驗證 npm pack 內容）
- [ ] `OPENCLAW_INSTALL_SMOKE_SKIP_NONROOT=1 pnpm test:install:smoke`（Docker 安裝煙霧測試，快速路徑；釋放前必須）
  - 如果已知立即前一個 npm 釋放已破損，為預安裝步驟設定 `OPENCLAW_INSTALL_SMOKE_PREVIOUS=<last-good-version>` 或 `OPENCLAW_INSTALL_SMOKE_SKIP_PREVIOUS=1`。
- [ ] （選擇性）完整安裝程式煙霧（新增非根 + CLI 覆蓋）：`pnpm test:install:smoke`
- [ ] （選擇性）安裝程式 E2E（Docker，執行 `curl -fsSL https://openclaw.ai/install.sh | bash`，上線，然後執行真實工具呼叫）：
  - `pnpm test:install:e2e:openai`（需要 `OPENAI_API_KEY`）
  - `pnpm test:install:e2e:anthropic`（需要 `ANTHROPIC_API_KEY`）
  - `pnpm test:install:e2e`（需要兩個金鑰；執行兩個提供者）
- [ ] （選擇性）如果你的更改影響傳送/接收路徑，對 web Gateway 進行抽查。

5. **macOS app（Sparkle）**

- [ ] 建置並簽署 macOS app，然後壓縮以供分發。
- [ ] 產生 Sparkle appcast（HTML 筆記透過 [`scripts/make_appcast.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/make_appcast.sh)）並更新 `appcast.xml`。
- [ ] 保留應用程式 zip（和可選的 dSYM zip）以附加到 GitHub 釋放。
- [ ] 遵循[macOS 釋放](/zh-Hant/platforms/mac/release)以取得確切命令和必要的環境變數。
  - `APP_BUILD` 必須是數字 + 單調（無 `-beta`），以便 Sparkle 正確比較版本。
  - 如果公證，使用從 App Store Connect API 環境變數建立的 `openclaw-notary` 鑰匙圈設定檔（詳見[macOS 釋放](/zh-Hant/platforms/mac/release)）。

6. **發佈（npm）**

- [ ] 確認 git 狀態乾淨；視需要認可並推送。
- [ ] 如果需要，執行 `npm login`（驗證 2FA）。
- [ ] `npm publish --access public`（使用 `--tag beta` 進行預釋放）。
- [ ] 驗證註冊表：`npm view openclaw version`、`npm view openclaw dist-tags` 和 `npx -y openclaw@X.Y.Z --version`（或 `--help`）。

### 疑難排解（來自 2.0.0-beta2 釋放的筆記）

- **npm pack/publish 掛起或產生巨大 tarball**：macOS app 套件束在 `dist/OpenClaw.app`（和釋放 zip）中被掃進套件。透過在 `package.json` `files` 中將發佈內容列入白名單來修正（包括 dist 子目錄、文件、技能；排除應用程式套件）。透過 `npm pack --dry-run` 確認 `dist/OpenClaw.app` 未列出。
- **分發標籤的 npm 驗證 web 迴圈**：使用舊版驗證以取得 OTP 提示：
  - `NPM_CONFIG_AUTH_TYPE=legacy npm dist-tag add openclaw@X.Y.Z latest`
- **`npx` 驗證失敗，出現 `ECOMPROMISED: Lock compromised`**：使用新鮮快取重試：
  - `NPM_CONFIG_CACHE=/tmp/npm-cache-$(date +%s) npx -y openclaw@X.Y.Z --version`
- **標籤在後期修正後需要重新指向**：強制更新並推送標籤，然後確保 GitHub 釋放資產仍然符合：
  - `git tag -f vX.Y.Z && git push -f origin vX.Y.Z`

7. **GitHub 釋放 + appcast**

- [ ] 標籤並推送：`git tag vX.Y.Z && git push origin vX.Y.Z`（或 `git push --tags`）。
- [ ] 為 `vX.Y.Z` 建立/刷新 GitHub 釋放，標題為 **`openclaw X.Y.Z`**（不只是標籤）；本文應包含該版本的**完整**變更記錄部分（重點 + 更改 + 修正）、內聯（無裸連結），且**不能在本文內重複標題**。
- [ ] 附加成品：`npm pack` tarball（選擇性）、`OpenClaw-X.Y.Z.zip` 和 `OpenClaw-X.Y.Z.dSYM.zip`（如果產生）。
- [ ] 認可更新的 `appcast.xml` 並推送（Sparkle 從 main 提供）。
- [ ] 從乾淨的暫存目錄（無 `package.json`），執行 `npx -y openclaw@X.Y.Z send --help` 以確認安裝/CLI 進入點有效。
- [ ] 宣佈/分享釋放筆記。

## 外掛程式發佈範圍（npm）

我們僅在 `@openclaw/*` 範圍下發佈**現有的 npm 外掛程式**。不在 npm 上的打包外掛程式保持**磁碟樹只讀**（仍在 `extensions/**` 中出出）。

衍生清單的程序：

1. `npm search @openclaw --json` 並擷取套件名稱。
2. 與 `extensions/*/package.json` 名稱進行比較。
3. 僅發佈**交集**（已在 npm 上）。

目前 npm 外掛程式清單（視需要更新）：

- @openclaw/bluebubbles
- @openclaw/diagnostics-otel
- @openclaw/discord
- @openclaw/feishu
- @openclaw/lobster
- @openclaw/matrix
- @openclaw/msteams
- @openclaw/nextcloud-talk
- @openclaw/nostr
- @openclaw/voice-call
- @openclaw/zalo
- @openclaw/zalouser

釋放筆記還必須說出**預設情況下不啟用**的**新選擇性打包外掛程式**（範例：`tlon`）。
