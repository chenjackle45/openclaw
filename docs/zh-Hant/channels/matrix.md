---
summary: "Matrix support status, capabilities, and configuration"
read_when:
  - Working on Matrix channel features
title: "Matrix"
---

# Matrix (plugin)

Matrix 是一個開放、去中心化的訊息協定。OpenClaw 作為 Matrix **使用者**連接至任何 homeserver，因此您需要 Matrix 帳戶給機器人。Beeper 也是有效的客戶端選項，但需要啟用 E2EE。

狀態：透過外掛支援 (@vector-im/matrix-bot-sdk)。支援直接訊息、房間、執行緒、媒體、反應、投票（傳送 + 投票開始為文字）、位置和 E2EE（具加密支援）。

## 需要外掛

Matrix 作為外掛提供，並未與核心安裝綑綁。

透過 CLI 安裝（npm registry）：

```bash
openclaw plugins install @openclaw/matrix
```

本地簽出（從 git repo 執行時）：

```bash
openclaw plugins install ./extensions/matrix
```

如果您在設定/入門期間選擇 Matrix 並偵測到 git 簽出，OpenClaw 將自動提供本地安裝路徑。

詳情：[外掛](/plugin)

## 設定

1. 安裝 Matrix 外掛：
   - 從 npm：`openclaw plugins install @openclaw/matrix`
   - 從本地簽出：`openclaw plugins install ./extensions/matrix`
2. 在 homeserver 上建立 Matrix 帳戶：
   - 瀏覽託管選項：[https://matrix.org/ecosystem/hosting/](https://matrix.org/ecosystem/hosting/)
   - 或自行託管。
3. 取得機器人帳戶的存取令牌：
   - 在您的主 server 使用 Matrix 登入 API 與 `curl`：

   ```bash
   curl --request POST \
     --url https://matrix.example.org/_matrix/client/v3/login \
     --header 'Content-Type: application/json' \
     --data '{
     "type": "m.login.password",
     "identifier": {
       "type": "m.id.user",
       "user": "your-user-name"
     },
     "password": "your-password"
   }'
   ```

   - 將 `matrix.example.org` 替換為您的 homeserver URL。
   - 或設定 `channels.matrix.userId` + `channels.matrix.password`：OpenClaw 呼叫相同登入端點、將存取令牌儲存在 `~/.openclaw/credentials/matrix/credentials.json`，並在下次啟動時重複使用。

4. 設定認證資訊：
   - 環境變數：`MATRIX_HOMESERVER`、`MATRIX_ACCESS_TOKEN`（或 `MATRIX_USER_ID` + `MATRIX_PASSWORD`）
   - 或設定：`channels.matrix.*`
   - 如果兩者都設定，設定優先。
   - 使用存取令牌：使用者 ID 透過 `/whoami` 自動提取。
   - 設定後，`channels.matrix.userId` 應為完整 Matrix ID（範例：`@bot:example.org`）。
5. 重啟 Gateway（或完成入門）。
6. 從任何 Matrix 客戶端開始與機器人的 DM 或邀請其加入房間
   （Element、Beeper 等；見 https://matrix.org/ecosystem/clients/）。Beeper 需要 E2EE，因此設定 `channels.matrix.encryption: true` 並驗證裝置。

最小設定（存取令牌，使用者 ID 自動提取）：

```json5
{
  channels: {
    matrix: {
      enabled: true,
      homeserver: "https://matrix.example.org",
      accessToken: "syt_***",
      dm: { policy: "pairing" },
    },
  },
}
```

E2EE 設定（端對端加密已啟用）：

```json5
{
  channels: {
    matrix: {
      enabled: true,
      homeserver: "https://matrix.example.org",
      accessToken: "syt_***",
      encryption: true,
      dm: { policy: "pairing" },
    },
  },
}
```

## 加密 (E2EE)

端對端加密透過 Rust crypto SDK **支援**。

使用 `channels.matrix.encryption: true` 啟用：

- 如果加密模組載入，加密房間自動解密。
- 外發媒體在傳送至加密房間時被加密。
- 初次連接時，OpenClaw 從您的其他會話請求裝置驗證。
- 在另一個 Matrix 客戶端（Element 等）中驗證裝置以啟用密鑰共享。
- 如果無法載入加密模組，E2EE 被停用且加密房間將不解密；OpenClaw 記錄警告。
- 如果您看到缺少加密模組錯誤（例如 `@matrix-org/matrix-sdk-crypto-nodejs-*`），允許 `@matrix-org/matrix-sdk-crypto-nodejs` 的建置指令碼並執行 `pnpm rebuild @matrix-org/matrix-sdk-crypto-nodejs` 或使用 `node node_modules/@matrix-org/matrix-sdk-crypto-nodejs/download-lib.js` 提取二進位。

加密狀態按帳戶 + 存取令牌儲存在 `~/.openclaw/matrix/accounts/<account>/<homeserver>__<user>/<token-hash>/crypto/`（SQLite 資料庫）。同步狀態與 `bot-storage.json` 相鄰。如果存取令牌（裝置）變更，新存儲被建立且機器人必須為加密房間重新驗證。

**裝置驗證：**
啟用 E2EE 時，機器人將在啟動時從您的其他會話請求驗證。開啟 Element（或另一個客戶端）並批准驗證請求以建立信任。驗證後，機器人可解密加密房間中的訊息。

## 路由模型

- 回覆始終返回 Matrix。
- DM 共享代理的主會話；房間對應至群組會話。

## 存取控制 (DM)

- 預設：`channels.matrix.dm.policy = "pairing"`。未知發送者獲得配對碼。
- 透過以下方式批准：
  - `openclaw pairing list matrix`
  - `openclaw pairing approve matrix <CODE>`
- 公開 DM：`channels.matrix.dm.policy="open"` 加上 `channels.matrix.dm.allowFrom=["*"]`。
- `channels.matrix.dm.allowFrom` 接受使用者 ID 或顯示名稱。精靈在目錄搜尋可用時將顯示名稱解析為使用者 ID。

## 房間（群組）

- 預設：`channels.matrix.groupPolicy = "allowlist"`（提及閘門）。當未設定時使用 `channels.defaults.groupPolicy` 覆蓋預設。
- 使用 `channels.matrix.groups` 允許清單房間（房間 ID、別名或名稱）：

```json5
{
  channels: {
    matrix: {
      groupPolicy: "allowlist",
      groups: {
        "!roomId:example.org": { allow: true },
        "#alias:example.org": { allow: true },
      },
      groupAllowFrom: ["@owner:example.org"],
    },
  },
}
```

- `requireMention: false` 啟用該房間的自動回覆。
- `groups."*"` 可跨房間設定提及閘門預設值。
- `groupAllowFrom` 限制哪些發送者可在房間中觸發機器人（選用）。
- 每房間 `users` 允許清單可進一步限制特定房間內的發送者。
- 設定精靈提示房間允許清單（房間 ID、別名或名稱）並可能時解析名稱。
- 啟動時，OpenClaw 解析允許清單中的房間/使用者名稱為 ID（當 Graph 權限允許）並記錄對應；未解析的項目保持原樣。
- 邀請預設自動加入；使用 `channels.matrix.autoJoin` 和 `channels.matrix.autoJoinAllowlist` 控制。
- 允許 **無房間**，設定 `channels.matrix.groupPolicy: "disabled"`（或保持空允許清單）。
- 舊版金鑰：`channels.matrix.rooms`（形狀與 `groups` 相同）。

## 執行緒

- 回覆執行緒被支援。
- `channels.matrix.threadReplies` 控制回覆是否停留在執行緒中：
  - `off`、`inbound`（預設）、`always`
- `channels.matrix.replyToMode` 控制未在執行緒中回覆時的回覆至中繼資料：
  - `off`（預設）、`first`、`all`

## 功能

| 功能            | 狀態                                                      |
| --------------- | --------------------------------------------------------- |
| 直接訊息        | ✅ 支援                                                   |
| 房間            | ✅ 支援                                                   |
| 執行緒          | ✅ 支援                                                   |
| 媒體            | ✅ 支援                                                   |
| E2EE            | ✅ 支援（需加密模組）                                     |
| 反應            | ✅ 支援（透過工具傳送/讀取）                              |
| 投票            | ✅ 傳送支援；入站投票開始轉換為文字（回應/結束被忽略）   |
| 位置            | ✅ 支援（geo URI；高度被忽略）                            |
| 原生命令        | ✅ 支援                                                   |

## 設定參考 (Matrix)

完整設定：[設定](/gateway/configuration)

提供商選項：

- `channels.matrix.enabled`：啟用/停用頻道啟動。
- `channels.matrix.homeserver`：homeserver URL。
- `channels.matrix.userId`：Matrix 使用者 ID（使用存取令牌時選用）。
- `channels.matrix.accessToken`：存取令牌。
- `channels.matrix.password`：登入密碼（令牌被儲存）。
- `channels.matrix.deviceName`：裝置顯示名稱。
- `channels.matrix.encryption`：啟用 E2EE（預設：false）。
- `channels.matrix.initialSyncLimit`：初始同步限制。
- `channels.matrix.threadReplies`：`off | inbound | always`（預設：inbound）。
- `channels.matrix.textChunkLimit`：外發文字分塊大小（字元）。
- `channels.matrix.chunkMode`：`length`（預設）或 `newline` 在長度分塊前在空白行（段落邊界）分割。
- `channels.matrix.dm.policy`：`pairing | allowlist | open | disabled`（預設：pairing）。
- `channels.matrix.dm.allowFrom`：DM 允許清單（使用者 ID 或顯示名稱）。`open` 需要 `"*"`。精靈可能時將名稱解析為 ID。
- `channels.matrix.groupPolicy`：`allowlist | open | disabled`（預設：allowlist）。
- `channels.matrix.groupAllowFrom`：群組訊息允許清單發送者。
- `channels.matrix.allowlistOnly`：對 DM + 房間強制允許清單規則。
- `channels.matrix.groups`：群組允許清單 + 每房間設定對應。
- `channels.matrix.rooms`：舊版群組允許清單/設定。
- `channels.matrix.replyToMode`：執行緒/標籤的回覆至模式。
- `channels.matrix.mediaMaxMb`：入站/外發媒體上限 (MB)。
- `channels.matrix.autoJoin`：邀請處理（`always | allowlist | off`，預設：always）。
- `channels.matrix.autoJoinAllowlist`：自動加入的允許房間 ID/別名。
- `channels.matrix.actions`：每動作工具閘門（反應/訊息/圖釘/成員資訊/頻道資訊）。
