---
title: "Model failover(模型容錯移轉)"
summary: "OpenClaw 如何輪換認證設定檔並在模型間進行回退"
read_when:
  - 診斷認證設定檔輪換、冷卻或模型回退行為
  - 更新認證設定檔或模型的故障轉移規則
---
# Model failover（模型故障轉移）

OpenClaw 分兩個階段處理失敗：
1. **認證設定檔輪換 (Auth profile rotation)**：在當前供應商內切換帳號。
2. **模型回退 (Model fallback)**：回退到 `agents.defaults.model.fallbacks` 中定義的下一個模型。

本文件解釋了運行時規則及其背後的數據。

## 認證儲存 (Keys + OAuth)

OpenClaw 將 API 金鑰和 OAuth 權仗都視為**認證設定檔 (auth profiles)**。

- 秘密（秘密資訊）存放於 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`。
- 設定中的 `auth.profiles` / `auth.order` 僅為**元資料與路由**（不含秘密資訊）。
- 舊版僅供匯入使用的 OAuth 檔案：`~/.openclaw/credentials/oauth.json`（在首次使用時匯入 `auth-profiles.json`）。

詳情請參閱：[/concepts/oauth](/concepts/oauth)

憑證類型：
- `type: "api_key"` → `{ provider, key }`
- `type: "oauth"` → `{ provider, access, refresh, expires, email? }`

## 設定檔 ID (Profile IDs)

OAuth 登入會建立獨特的設定檔，以便多個帳戶共存。
- 預設值：當無法取得電子郵件時使用 `provider:default`。
- 有電子郵件的 OAuth：`provider:<email>`（例如 `google-antigravity:user@gmail.com`）。

設定檔儲存在 `auth-profiles.json` 的 `profiles` 欄位下。

## 輪換順序

當一個供應商有多個設定檔時，OpenClaw 會按以下順序選擇：

1. **明確設定**：`auth.order[provider]`（如果已設定）。
2. **設定過的設定檔**：按供應商篩選過的 `auth.profiles`。
3. **儲存的設定檔**：`auth-profiles.json` 中該供應商的條目。

如果未設定明確順序，OpenClaw 使用輪詢 (round‑robin) 順序：
- **主要依據**：設定檔類型（**OAuth 優先於 API 金鑰**）。
- **次要依據**：`usageStats.lastUsed`（最久未使用的優先）。
- **冷卻中/停用的設定檔**會被移到最後，並按到期時間排序。

### 會話黏性 (Session stickiness)

OpenClaw 會為**每個會話固定所選的認證設定檔**，以保持供應商快取的熱度。它**不會**在每次請求時輪換。固定的設定檔會一直重複使用，直到：
- 會話被重置 (`/new` / `/reset`)
- 壓縮 (compaction) 完成（壓縮計數增加）
- 該設定檔進入冷卻或被停用

透過 `/model …@<profileId>` 手動選擇會為該會話設定 **使用者覆寫 (user override)**，且在開始新會話前不會自動輪換。

自動固定的設定檔（由會話路由選擇）被視為一種**偏好 (preference)**：它們會先被嘗試，但 OpenClaw 可能會因速率限制/超時而輪換到另一個設定檔。使用者固定的設定檔則會鎖定在該設定檔上；如果失敗且設定了模型回退，OpenClaw 將移至下一個模型，而不是切換設定檔。

## 冷卻 (Cooldowns)

當設定檔因認證/速率限制錯誤（或看起來像速率限制的超時）失敗時，OpenClaw 將其標記為冷卻中，並移至下一個設定檔。格式/無效請求錯誤也會觸發同樣的冷卻機制。

冷卻使用指數退避 (exponential backoff)：
- 1 分鐘
- 5 分鐘
- 25 分鐘
- 1 小時（上限）

狀態儲存在 `auth-profiles.json` 的 `usageStats` 下。

## 帳單停用 (Billing disables)

帳單/餘額失敗（例如「額度不足」/「餘額過低」）會觸發故障轉移，但通常不是暫時性的。OpenClaw 不會使用短暫的冷卻，而是將設定檔標記為**停用 (disabled)**（退避時間較長），並輪換到下一個設定檔/供應商。

預設值：
- 帳單退避從 **5 小時**開始，每次失敗翻倍，上限 **24 小時**。
- 如果設定檔在 **24 小時**內未發生失敗，則退避計數器會重置。

## 模型回退 (Model fallback)

如果供應商的所有設定檔都失敗，OpenClaw 會移至 `agents.defaults.model.fallbacks` 中的下一個模型。這適用於認證失敗、速率限制和耗盡設定檔輪換的超時（其他錯誤不會觸發回退）。

當運行開始時帶有模型覆寫（透過掛鉤或 CLI）時，在嘗試完所有設定的回退模型後，最終仍會回到 `agents.defaults.model.primary`。

## 相關設定

請參閱 [Gateway 設定](/gateway/configuration) 了解：
- `auth.profiles` / `auth.order`
- `auth.cooldowns.*`
- `agents.defaults.model.primary` / `fallbacks`
- `agents.defaults.imageModel` 路由

請參閱 [Models](/concepts/models) 了解更廣泛的模型選擇和回退概覽。
