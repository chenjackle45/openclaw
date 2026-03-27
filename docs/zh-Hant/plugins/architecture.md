---
summary: "Plugin internals: capability model, ownership, contracts, load pipeline, and runtime helpers（Plugin 內部：能力模型、所有權、合約、載入 pipeline 與 runtime 輔助函式）"
read_when:
  - 建置或 debug 原生 OpenClaw 外掛
  - 理解 plugin 能力模型或所有權邊界
  - 在 plugin 載入 pipeline 或註冊表上工作
  - 實作 provider runtime hooks 或 channel 外掛
title: "Plugin Internals（Plugin 內部）"
sidebarTitle: "內部"
---

# Plugin Internals

<Info>
  這是 **深度架構參考**。針對實用指南，參考：
  - [安裝與使用外掛](/zh-Hant/tools/plugin) — 使用者指南
  - [入門指南](/zh-Hant/plugins/building-plugins) — 第一個外掛教程
  - [Channel 外掛](/zh-Hant/plugins/sdk-channel-plugins) — 建置傳訊頻道
  - [Provider 外掛](/zh-Hant/plugins/sdk-provider-plugins) — 建置模型 provider
  - [SDK 概述](/zh-Hant/plugins/sdk-overview) — import 對應表與註冊 API
</Info>

本頁涵蓋 OpenClaw plugin 系統的內部架構。

## 公開能力模型

能力是 OpenClaw 內的公開 **原生外掛** 模型。每個原生 OpenClaw 外掛針對一個或多個能力類型註冊：

| 能力                | 註冊方法                                      | 範例外掛                  |
| ------------------- | --------------------------------------------- | ------------------------- |
| 文字推理            | `api.registerProvider(...)`                   | `openai`, `anthropic`     |
| 語音                | `api.registerSpeechProvider(...)`             | `elevenlabs`, `microsoft` |
| Media understanding | `api.registerMediaUnderstandingProvider(...)` | `openai`, `google`        |
| 圖像生成            | `api.registerImageGenerationProvider(...)`    | `openai`, `google`        |
| 網路搜尋            | `api.registerWebSearchProvider(...)`          | `google`                  |
| Channel／傳訊       | `api.registerChannel(...)`                    | `msteams`, `matrix`       |

不註冊任何能力但提供 hooks、工具或服務的外掛是 **legacy hook-only** 外掛。該模式仍然完全支援。

### 外部相容性立場

能力模型在核心中實施，今天由捆綁／原生外掛使用，但外部外掛相容性仍需要比「它被匯出，所以它被凍結」更嚴格的門檻。

目前指導：

- **現有外部外掛：** 保持基於 hook 的整合運作；將這視為相容性基線
- **新捆綁／原生外掛：** 優先選擇明確能力註冊而不是廠商特定的深層或新的 hook-only 設計
- **採用能力註冊的外部外掛：** 允許，但將能力特定的輔助函式介面視為演變，除非文件明確標記合約為穩定

實踐規則：

- 能力註冊 API 是預期方向
- legacy hooks 在過渡期間對外部外掛保持最安全的無中斷路徑
- 匯出的輔助函式 subpath 並非全部相等；優先選擇窄文件合約，而不是偶然的輔助函式匯出

### Plugin 形狀

OpenClaw 根據其實際註冊行為（不只是靜態中繼資料）將每個已載入的外掛分類為一種形狀：

- **plain-capability** -- 精確註冊一個能力型別（例如僅 provider 外掛如 `mistral`）
- **hybrid-capability** -- 註冊多個能力型別（例如 `openai` 擁有文字推理、語音、media understanding 與圖像生成）
- **hook-only** -- 只註冊 hooks（類型化或自訂），沒有能力、工具、命令或服務
- **non-capability** -- 註冊工具、命令、服務或 routes 但沒有能力

使用 `openclaw plugins inspect <id>` 以查看外掛的形狀與能力分解。參考 [CLI 參考](/zh-Hant/cli/plugins#inspect) 以取得詳細資訊。

### Legacy hooks

`before_agent_start` hook 保持作為 hook-only 外掛的相容性路徑支援。Legacy 真實世界外掛仍然依賴它。

方向：

- 保持它運作
- 將其記錄為 legacy
- 優先選擇 `before_model_resolve` 以進行模型／provider 覆蓋工作
- 優先選擇 `before_prompt_build` 以進行 prompt 變異工作
- 只在真實使用量下降且 fixture 涵蓋證明遷移安全性後移除

### 相容性信號

當你執行 `openclaw doctor` 或 `openclaw plugins inspect <id>` 時，你可能會看到其中一個標籤：

| 信號                       | 意義                                         |
| -------------------------- | -------------------------------------------- |
| **config valid**           | Config 解析良好且外掛解析                    |
| **compatibility advisory** | 外掛使用支援但較舊的模式（例如 `hook-only`） |
| **legacy warning**         | 外掛使用 `before_agent_start`，已棄用        |
| **hard error**             | Config 無效或外掛載入失敗                    |

既不是 `hook-only` 也不是 `before_agent_start` 會今天破壞你的外掛 -- `hook-only` 是建議，`before_agent_start` 只觸發警告。這些信號也出現在 `openclaw status --all` 與 `openclaw plugins doctor` 中。

## 架構概述

OpenClaw 的 plugin 系統有四層：

1. **Manifest + 發現**
   OpenClaw 從已設定的路徑、工作區根、全球擴充根與捆綁擴充查找候選外掛。發現首先讀取原生 `openclaw.plugin.json` manifests 加上支援的 bundle manifests。
2. **啟用 + 驗證**
   Core 決定發現的外掛是啟用、禁用、阻止還是為獨佔插槽（如 memory）選擇。
3. **Runtime 載入**
   原生 OpenClaw 外掛透過 jiti 進行處理中載入並將能力註冊到中央註冊表。相容的 bundles 被正規化為註冊表記錄，不匯入 runtime 代碼。
4. **介面消費**
   OpenClaw 的其餘部分讀取註冊表以公開工具、channels、provider setup、hooks、HTTP routes、CLI 命令與服務。

重要的設計邊界：

- 發現 + config 驗證應該在 **manifest/schema 中繼資料** 上工作，而不執行外掛代碼
- 原生 runtime 行為來自外掛模組的 `register(api)` 路徑

該分割讓 OpenClaw 驗證 config、解釋遺漏／禁用的外掛，並在完整 runtime 有效前建立 UI/schema 提示。

### Channel 外掛與共享訊息工具

Channel 外掛不需要為正常聊天操作註冊單獨的 send／edit／react 工具。OpenClaw 在核心中保留一個共享 `message` 工具，channel 外掛擁有 channel 特定的發現與執行。

目前的邊界：

- core 擁有共享 `message` 工具主機、prompt 配線、工作階段／執行緒簿記與執行分派
- channel 外掛擁有範疇化操作發現、能力發現與任何 channel 特定的 schema 貢獻
- channel 外掛透過其操作 adapter 執行最後操作

Channel 外掛，SDK 介面是 `ChannelMessageActionAdapter.describeMessageTool(...)`。該統一發現呼叫讓外掛傳回其可見操作、能力與 schema 貢獻，使這些部分不會分散。

Core 將 runtime 範疇傳遞到該發現步驟。重要欄位包括：

- `accountId`
- `currentChannelId`
- `currentThreadTs`
- `currentMessageId`
- `sessionKey`
- `sessionId`
- `agentId`
- trusted inbound `requesterSenderId`

那對於脈絡敏感的外掛重要。Channel 可以根據活躍 account、目前 room／執行緒／訊息或 trusted requester 身分隱藏或暴露訊息操作，不需在核心 `message` 工具中硬編碼 channel 特定分支。

這是為什麼嵌入式 runner routing 變更仍然是外掛工作：runner 負責將目前聊天／工作階段身分轉發到外掛發現邊界，所以共享 `message` 工具為目前回合暴露正確的 channel 擁有介面。

針對 channel 擁有的執行輔助函式，捆綁外掛應在其自己的擴充模組內保持執行 runtime。Core 不再擁有 Discord、Slack、Telegram 或 WhatsApp message-action runtimes 在 `src/agents/tools` 下。我們不發佈單獨的 `plugin-sdk/*-action-runtime` subpaths，捆綁外掛應直接從其擴充擁有的模組 import 他們自己的本地 runtime 代碼。

針對 polls，有兩個執行路徑：

- `outbound.sendPoll` 是適合通用 poll 模型的 channels 的共享基線
- `actions.handleAction("poll")` 是 channel 特定的 poll 語意或額外 poll 參數的偏好路徑

Core 現在延遲共享 poll 解析，直到在外掛 poll 分派拒絕操作後，所以外掛擁有的 poll handlers 可接受 channel 特定的 poll 欄位，不會首先被泛用 poll 解析器阻止。

## 能力所有權模型

OpenClaw 將原生外掛視為 **公司** 或 **功能** 的所有權邊界，不是不相關整合的雜牌。

那意味著：

- 公司外掛應該通常擁有該公司的所有 OpenClaw 朝向介面
- 功能外掛應該通常擁有它介紹的完整功能介面
- channels 應消費共享核心能力而不是重新實作 provider 行為臨時

範例：

- 捆綁 `openai` 外掛擁有 OpenAI 模型 provider 行為與 OpenAI 語音 + media-understanding + 圖像生成行為
- 捆綁 `elevenlabs` 外掛擁有 ElevenLabs 語音行為
- 捆綁 `microsoft` 外掛擁有 Microsoft 語音行為
- 捆綁 `google` 外掛擁有 Google 模型 provider 行為加上 Google media-understanding + 圖像生成 + 網路搜尋行為
- 捆綁 `minimax`、`mistral`、`moonshot` 與 `zai` 外掛擁有他們的 media-understanding backends
- `voice-call` 外掛是功能外掛：它擁有呼叫傳輸、工具、CLI、routes 與 runtime，但消費核心 TTS/STT 能力而不是發明第二個語音堆疊

預期的結束狀態：

- OpenAI 住在一個外掛中，即使它跨越文字模型、語音、圖像與未來影片
- 另一個供應商可以為其自己的介面做相同
- channels 不在乎哪個廠商外掛擁有 provider；他們消費核心公開的共享能力合約

這是關鍵區別：

- **外掛** = 所有權邊界
- **能力** = 多個外掛可實作或消費的核心合約

所以如果 OpenClaw 加入新的領域如影片，第一個問題不是「哪個 provider 應該硬編碼影片處理？」第一個問題是「什麼是核心影片能力合約？」一旦該合約存在，廠商外掛可針對它註冊，channel／功能外掛可消費它。

如果能力尚不存在，正確的舉動通常是：

1. 在核心中定義遺漏的能力
2. 透過 plugin API/runtime 以類型化方式公開它
3. 針對該能力配線 channels／features
4. 讓廠商外掛註冊實作

這保持所有權明確，同時避免依賴單一廠商或單次外掛特定代碼路徑的核心行為。

### 能力分層

決定代碼歸屬時使用此心智模型：

- **核心能力層**：共享協調、策略、回退、config 合併規則、遞送語意與類型化合約
- **廠商外掛層**：廠商特定 API、auth、模型目錄、語音合成、圖像生成、未來影片 backends、使用情況端點
- **channel／功能外掛層**：Slack/Discord/voice-call/等整合，消費核心能力與在介面上呈現它們

例如，TTS 遵循此形狀：

- core 擁有回覆時間 TTS 策略、回退順序、偏好與 channel 遞送
- `openai`、`elevenlabs` 與 `microsoft` 擁有合成實作
- `voice-call` 消費電話 TTS runtime 輔助函式

未來能力應優先採用相同模式。

### 多能力公司外掛範例

公司外掛在外部應感覺凝聚。如果 OpenClaw 對模型、語音、media understanding 與網路搜尋有共享合約，廠商可在一個地方擁有其所有介面。

（詳細程式碼範例請參考英文版）

重要是不是確切的輔助函式名稱。形狀重要：

- 一個外掛擁有廠商介面
- core 仍擁有能力合約
- channels 與功能外掛消費 `api.runtime.*` 輔助函式，不是廠商代碼
- 合約測試可聲稱外掛註冊了它聲稱擁有的能力

### 能力範例：影片理解

OpenClaw 已經將圖像／音訊／影片理解視為一個共享能力。相同的所有權模型也適用：

1. core 定義 media-understanding 合約
2. 廠商外掛註冊 `describeImage`、`transcribeAudio` 與 `describeVideo`（適用時）
3. channels 與功能外掛消費共享核心行為，而不直接配線到廠商代碼

這避免將一個 provider 的影片假設烘焙到核心。外掛擁有廠商介面；core 擁有能力合約與回退行為。

如果 OpenClaw 稍後加入新的領域，如影片生成，再次使用相同的序列：先定義核心能力，然後讓廠商外掛針對它註冊實作。

需要具體推出檢查清單？參考 [能力烹飪書](/zh-Hant/tools/capability-cookbook)。

## 合約與強制

Plugin API 介面有意在 `OpenClawPluginApi` 中類型化與集中。該合約定義支援的註冊點與外掛可仰賴的 runtime 輔助函式。

為什麼這重要：

- 外掛作者取得一個穩定的內部標準
- core 可拒絕重複所有權，如兩個外掛註冊相同的 provider id
- startup 可為格式不良的註冊呈現可行動的診斷
- 合約測試可強制捆綁外掛所有權並防止無聲漂移

有兩層強制：

1. **runtime 註冊強制**
   Plugin 註冊表在外掛載入時驗證註冊。範例：重複 provider id、重複語音 provider id 與格式不良的註冊產生 plugin 診斷而不是未定義行為。
2. **合約測試**
   捆綁外掛在測試執行期間被捕獲在合約註冊表中，所以 OpenClaw 可明確聲稱所有權。今天這被用於模型 providers、語音 providers、網路搜尋 providers 與捆綁的註冊所有權。

實踐效果是 OpenClaw 預先知道哪個外掛擁有哪個介面。這讓 core 與 channels 無縫組合，因為所有權被宣告、類型化與可測試，而不隱含。

### 什麼屬於合約

好的 plugin 合約是：

- 類型化
- 小
- 能力特定
- 由 core 擁有
- 可被多個外掛重複使用
- 可被 channels／features 消費，不需廠商知識

壞的 plugin 合約：

- 廠商特定策略隱藏在 core
- 一次外掛脫離，繞過註冊表
- channel 代碼直接到達廠商實作
- 不是 `OpenClawPluginApi` 或 `api.runtime` 一部分的臨時 runtime 物件

當有疑問時，提升抽象層：先定義能力，然後讓外掛插入它。

## 執行模型

原生 OpenClaw 外掛 **處理中** 與 Gateway 執行。它們不被沙盒化。已載入的原生外掛具有與核心代碼相同的處理級信任邊界。

含意：

- 原生外掛可註冊工具、網路 handlers、hooks 與服務
- 原生外掛錯誤可當機或使 gateway 不穩定
- 惡意原生外掛等同於 OpenClaw 處理內的任意代碼執行

相容 bundles 預設更安全，因為 OpenClaw 目前將它們視為中繼資料／內容包。在目前版本中，那主要意味著捆綁技能。

針對非捆綁外掛使用 allowlists 與明確安裝／載入路徑。將工作區外掛視為開發時間代碼，不是生產預設。

針對捆綁的工作區套件名稱，將 plugin id 錨定在 npm 名稱中：`@openclaw/<id>` 預設，或經批准的類型化後綴如 `-provider`、`-plugin`、`-speech`、`-sandbox` 或 `-media-understanding`，當套件有意暴露更窄的 plugin 角色時。

重要信任注意：

- `plugins.allow` 信任 **plugin ids**，不是來源來處。
- 與捆綁外掛具有相同 id 的工作區外掛有意在該工作區外掛啟用／allowlisted 時遮蔽捆綁複本。
- 這正常且對本地開發、patch 測試與 hotfixes 有用。

## 匯出邊界

OpenClaw 匯出能力，不是實作便利。

保持能力註冊公開。修剪非合約輔助函式匯出：

- 捆綁外掛特定輔助函式 subpaths
- 不打算為公開 API 的 runtime 配管 subpaths
- 廠商特定便利輔助函式
- 實作詳細的 setup/onboarding 輔助函式

## 載入 pipeline

在 startup，OpenClaw 大致做這個：

1. 發現候選 plugin 根
2. 讀取原生或相容 bundle manifests 與套件中繼資料
3. 拒絕不安全候選
4. 正規化 plugin config（`plugins.enabled`、`allow`、`deny`、`entries`、`slots`、`load.paths`）
5. 決定每個候選的啟用
6. 透過 jiti 載入啟用的原生模組
7. 呼叫原生 `register(api)` hooks 並收集註冊到 plugin 註冊表
8. 公開註冊表到命令/runtime 介面

安全門發生 **before** runtime 執行。候選在 entry 脫離 plugin 根、路徑為全球可寫或非捆綁外掛的路徑所有權看起來可疑時被阻止。

### Manifest-first 行為

Manifest 是 control-plane 事實來源。OpenClaw 使用它：

- 識別外掛
- 發現已宣告的 channels／skills／config schema 或 bundle 能力
- 驗證 `plugins.entries.<id>.config`
- 擴充 Control UI 標籤／佔位符
- 顯示安裝／目錄中繼資料

針對原生外掛，runtime 模組是資料面部分。它註冊實際行為，如 hooks、工具、命令或 provider flows。

### Loader 快取什麼

OpenClaw 為以下項目保留短期處理中快取：

- 發現結果
- Manifest 註冊表資料
- 已載入的 plugin 註冊表

這些快取減少突發 startup 與重複命令開銷。將它們視為短期效能快取而不是持久性是安全的。

效能注意：

- 設定 `OPENCLAW_DISABLE_PLUGIN_DISCOVERY_CACHE=1` 或 `OPENCLAW_DISABLE_PLUGIN_MANIFEST_CACHE=1` 以禁用這些快取。
- 使用 `OPENCLAW_PLUGIN_DISCOVERY_CACHE_MS` 與 `OPENCLAW_PLUGIN_MANIFEST_CACHE_MS` 調整快取視窗。

## 註冊表模型

已載入的外掛不直接變異隨機核心全局變數。它們註冊到中央 plugin 註冊表。

註冊表跟蹤：

- plugin 記錄（身分、來源、來處、狀態、診斷）
- 工具
- legacy hooks 與類型化 hooks
- channels
- providers
- gateway RPC handlers
- HTTP routes
- CLI registrars
- 背景服務
- 外掛擁有的命令

Core 功能然後從該註冊表讀取而不是直接與外掛模組談話。這保持載入單向：

- plugin 模組 -> 註冊表註冊
- core runtime -> 註冊表消費

該分離對可維護性重要。它意味著大多數核心介面只需要一個整合點：「讀取註冊表」，不是「每個外掛模組特例」。

## Conversation binding 回調

可綁定 conversation 的外掛可在批准被解析時反應。

使用 `api.onConversationBindingResolved(...)` 以在 bind 請求被批准或拒絕後收到回調：

```ts
export default {
  id: "my-plugin",
  register(api) {
    api.onConversationBindingResolved(async (event) => {
      if (event.status === "approved") {
        // 綁定現在對此外掛 + conversation 存在。
        console.log(event.binding?.conversationId);
        return;
      }

      // 請求被拒絕；清除任何本地待決狀態。
      console.log(event.request.conversation.conversationId);
    });
  },
};
```

回調有效載荷欄位：

- `status`：`"approved"` 或 `"denied"`
- `decision`：`"allow-once"`、`"allow-always"` 或 `"deny"`
- `binding`：已批准請求的已解析綁定
- `request`：原始請求摘要、分離提示、寄件者 id 與 conversation 中繼資料

此回調是通知專用。它不改變誰被允許綁定 conversation，且它在核心批准處理完成後執行。

## Provider runtime hooks

Provider 外掛現在有兩層：

- manifest 中繼資料：`providerAuthEnvVars` 用於在 runtime 載入前的便宜 env-auth 查詢，加上 `providerAuthChoices` 用於在 runtime 載入前的便宜 onboarding/auth-choice 標籤與 CLI flag 中繼資料
- config 時間 hooks：`catalog` / legacy `discovery`
- runtime hooks：`resolveDynamicModel`、`prepareDynamicModel`、`normalizeResolvedModel`、`capabilities`、`prepareExtraParams`、`wrapStreamFn`、`formatApiKey`、`refreshOAuth`、`buildAuthDoctorHint`、`isCacheTtlEligible`、`buildMissingAuthMessage`、`suppressBuiltInModel`、`augmentModelCatalog`、`isBinaryThinking`、`supportsXHighThinking`、`resolveDefaultThinkingLevel`、`isModernModelRef`、`prepareRuntimeAuth`、`resolveUsageAuth`、`fetchUsageSnapshot`

OpenClaw 仍擁有泛用 agent loop、failover、transcript 處理與工具策略。這些 hooks 是 provider 特定行為的擴充介面，不需要整個自訂推理傳輸。

當 provider 有應不載入 plugin runtime 即可看到的基於 env 認證時使用 manifest `providerAuthEnvVars`。當 onboarding/auth-choice CLI 介面應知道 provider 的選擇 id、組標籤與簡單單 flag auth 配線，不載入 provider runtime 時，使用 manifest `providerAuthChoices`。保持 provider runtime `envVars` 用於操作員朝向提示，如 onboarding 標籤或 OAuth client-id/client-secret setup 變數。

### Hook 順序與使用

針對模型/provider 外掛，OpenClaw 按此粗略順序呼叫 hooks。「何時使用」欄是快速決策指南。

| #   | Hook                          | 功能                                                                  | 何時使用                                                     |
| --- | ----------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| 1   | `catalog`                     | 在 `models.json` 生成期間將 provider config 發佈到 `models.providers` | Provider 擁有目錄或基礎 URL 預設值                           |
| --  | _(built-in model lookup)_     | OpenClaw 首先嘗試正常註冊表/目錄路徑                                  | _(不是 plugin hook)_                                         |
| 2   | `resolveDynamicModel`         | 針對尚未在本地註冊表中的 provider 擁有的模型 id 的同步回退            | Provider 接受任意上游模型 id                                 |
| 3   | `prepareDynamicModel`         | 非同步預熱，然後 `resolveDynamicModel` 再次執行                       | Provider 在解析未知 id 前需要網路中繼資料                    |
| 4   | `normalizeResolvedModel`      | 在嵌入式 runner 使用已解析模型前最終重寫                              | Provider 需要傳輸重寫但仍使用核心傳輸                        |
| 5   | `capabilities`                | Provider 擁有的 transcript/tooling 中繼資料被共享核心邏輯使用         | Provider 需要 transcript/provider-family 怪癖                |
| 6   | `prepareExtraParams`          | 在泛用 stream 選項 wrappers 前請求參數正規化                          | Provider 需要預設請求參數或按 provider 參數清理              |
| 7   | `wrapStreamFn`                | Stream wrapper 應用泛用 wrappers 後                                   | Provider 需要請求標頭/請求內容/模型相容 wrappers 不自訂傳輸  |
| 8   | `formatApiKey`                | Auth-profile formatter：存儲的 profile 變成 runtime `apiKey` 字串     | Provider 儲存額外 auth 中繼資料且需要自訂 runtime token 形狀 |
| 9   | `refreshOAuth`                | OAuth 重新整理覆蓋針對自訂重新整理端點或重新整理失敗策略              | Provider 不適合共享 `pi-ai` refreshers                       |
| 10  | `buildAuthDoctorHint`         | OAuth 重新整理失敗時附加修復提示                                      | Provider 在重新整理失敗後需要 provider 擁有的 auth 修復指導  |
| 11  | `isCacheTtlEligible`          | Prompt-cache 策略針對代理/backhaul providers                          | Provider 需要代理特定 cache TTL 控制                         |
| 12  | `buildMissingAuthMessage`     | 泛用 missing-auth 回復訊息的替代                                      | Provider 需要 provider 特定 missing-auth 回復提示            |
| 13  | `suppressBuiltInModel`        | 過時上游模型壓制加上可選使用者朝向錯誤提示                            | Provider 需要隱藏過時上游列或用廠商提示替代                  |
| 14  | `augmentModelCatalog`         | 發現後附加的合成/最後目錄列                                           | Provider 需要 `models list` 與 pickers 中的合成前向相容列    |
| 15  | `isBinaryThinking`            | 針對 binary-thinking providers 的開/關 reasoning 切換                 | Provider 僅公開 binary thinking 開/關                        |
| 16  | `supportsXHighThinking`       | 所選模型的 `xhigh` reasoning 支持                                     | Provider 想要 `xhigh` 僅在模型子集上                         |
| 17  | `resolveDefaultThinkingLevel` | 特定模型家族的預設 `/think` 等級                                      | Provider 擁有模型家族的預設 `/think` 策略                    |
| 18  | `isModernModelRef`            | 針對即時 profile 過濾與 smoke 選擇的現代模型匹配器                    | Provider 擁有即時/smoke 偏好模型匹配                         |
| 19  | `prepareRuntimeAuth`          | 在推理前交換已設定認證到實際 runtime token/key                        | Provider 需要 token exchange 或短期請求認證                  |
| 20  | `resolveUsageAuth`            | 針對 `/usage` 與相關狀態介面解析使用情況/帳單認證                     | Provider 需要自訂使用情況/quota token 解析或不同使用情況認證 |
| 21  | `fetchUsageSnapshot`          | 在 auth 被解析後取得與正規化 provider 特定使用情況/quota 快照         | Provider 需要 provider 特定使用情況端點或有效載荷解析器      |

如果 provider 需要完全自訂連線協議或自訂請求執行器，那是擴充的不同類。這些 hooks 針對仍在 OpenClaw 的正常推理 loop 上執行的 provider 行為。

由於篇幅限制，詳細的 hook 範例，內建範例與後續部分請參考英文版本。這份文件涵蓋了主要的 Plugin 內部架構概念。
