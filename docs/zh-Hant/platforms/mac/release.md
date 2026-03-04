---
summary: "OpenClaw macOS 發行版本檢查清單（Sparkle feed、包裝、簽署）"
read_when:
  - Cutting or validating a OpenClaw macOS release
  - Updating the Sparkle appcast or feed assets
title: "macOS Release（macOS 發行版本）"
---

# OpenClaw macOS 發行版本（Sparkle）

此應用現在配備 Sparkle 自動更新。發行版本構建必須使用開發者 ID 簽署、壓縮並與已簽署的 appcast 項目一起發佈。

## 先決條件

- 已安裝開發者 ID Application 憑證（範例：`Developer ID Application: <Developer Name> (<TEAMID>)`）。
- Sparkle 私密金鑰路徑設定在環境中作為 `SPARKLE_PRIVATE_KEY_FILE`（您的 Sparkle ed25519 私密金鑰的路徑；公開金鑰已烤入 Info.plist）。如果缺少，請檢查 `~/.profile`。
- `xcrun notarytool` 的公證認證（鑰匙圈設定檔或 API 金鑰），如果您想要 Gatekeeper 安全的 DMG/zip 發佈。
  - 我們使用名為 `openclaw-notary` 的鑰匙圈設定檔，從 shell 設定檔中的 App Store Connect API 金鑰環境變數建立：
    - `APP_STORE_CONNECT_API_KEY_P8`、`APP_STORE_CONNECT_KEY_ID`、`APP_STORE_CONNECT_ISSUER_ID`
    - `echo "$APP_STORE_CONNECT_API_KEY_P8" | sed 's/\\n/\n/g' > /tmp/openclaw-notary.p8`
    - `xcrun notarytool store-credentials "openclaw-notary" --key /tmp/openclaw-notary.p8 --key-id "$APP_STORE_CONNECT_KEY_ID" --issuer "$APP_STORE_CONNECT_ISSUER_ID"`
- 已安裝 `pnpm` 依賴項（`pnpm install --config.node-linker=hoisted`）。
- Sparkle 工具透過 SwiftPM 在 `apps/macos/.build/artifacts/sparkle/Sparkle/bin/` 自動擷取（`sign_update`、`generate_appcast` 等）。

## 構建和打包

備註：

- `APP_BUILD` 對應至 `CFBundleVersion`/`sparkle:version`；保持為數字 + 單調（無 `-beta`），否則 Sparkle 會將其視為相等。
- 預設為目前架構（`$(uname -m)`）。針對發行/通用構建，設定 `BUILD_ARCHS="arm64 x86_64"`（或 `BUILD_ARCHS=all`）。
- 針對發行成品（zip + DMG + 公證），使用 `scripts/package-mac-dist.sh`。針對本機/開發打包，使用 `scripts/package-mac-app.sh`。

```bash
# 從儲存庫根；設定發行版本 ID，以便啟用 Sparkle 訂閱。
# APP_BUILD 必須為數字 + 單調，以供 Sparkle 比較。
BUNDLE_ID=ai.openclaw.mac \
APP_VERSION=2026.3.2 \
BUILD_CONFIG=release \
SIGN_IDENTITY=”Developer ID Application: <Developer Name> (<TEAMID>)” \
scripts/package-mac-app.sh

# 壓縮以供分佈（包含 Sparkle 增量支援的資源 forks）
ditto -c -k --sequesterRsrc --keepParent dist/OpenClaw.app dist/OpenClaw-2026.3.2.zip

# 選用：也為人類構建一個樣式化的 DMG（拖到 /Applications）
scripts/create-dmg.sh dist/OpenClaw.app dist/OpenClaw-2026.3.2.dmg

# 建議：構建 + 公證/裝訂 zip + DMG
# 首先，建立一次鑰匙圈設定檔：
#   xcrun notarytool store-credentials “openclaw-notary” \
#     --apple-id “<apple-id>” --team-id “<team-id>” --password “<app-specific-password>”
NOTARIZE=1 NOTARYTOOL_PROFILE=openclaw-notary \
BUNDLE_ID=ai.openclaw.mac \
APP_VERSION=2026.3.2 \
BUILD_CONFIG=release \
SIGN_IDENTITY=”Developer ID Application: <Developer Name> (<TEAMID>)” \
scripts/package-mac-dist.sh

# 選用：隨發行版本一起提供 dSYM
ditto -c -k --keepParent apps/macos/.build/release/OpenClaw.app.dSYM dist/OpenClaw-2026.3.2.dSYM.zip
```

## Appcast 項目

使用版本說明產生器以便 Sparkle 轉譯格式化的 HTML 筆記：

```bash
SPARKLE_PRIVATE_KEY_FILE=/path/to/ed25519-private-key scripts/make_appcast.sh dist/OpenClaw-2026.3.2.zip https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml
```

從 `CHANGELOG.md`（透過 [`scripts/changelog-to-html.sh`](https://github.com/openclaw/openclaw/blob/main/scripts/changelog-to-html.sh)）產生 HTML 發行說明，並將其嵌入 appcast 項目中。
發佈時，將更新的 `appcast.xml` 與發行資產（zip + dSYM）一起提交。

## 發佈與驗證

- 將 `OpenClaw-2026.3.2.zip`（和 `OpenClaw-2026.3.2.dSYM.zip`）上傳到標籤 `v2026.3.2` 的 GitHub 發行版本。
- 確保原始 appcast URL 與烤入的訂閱相符：`https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml`。
- 合理性檢查：
  - `curl -I https://raw.githubusercontent.com/openclaw/openclaw/main/appcast.xml` 傳回 200。
  - `curl -I <enclosure url>` 在資產上傳後傳回 200。
  - 在先前的公開構建上，從 About 標籤執行「檢查更新…」並驗證 Sparkle 乾淨地安裝新構建。

完成定義：已簽署的應用 + appcast 已發佈，更新流程可從較舊的已安裝版本運作，發行資產已附加到 GitHub 發行版本。
