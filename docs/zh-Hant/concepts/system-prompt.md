---
title: "System prompt(系統提示詞)"
summary: "OpenClaw 系統提示詞包含什麼以及如何組裝"
read_when:
  - 編輯系統提示詞文字、工具列表或時間/心跳部分
  - 更改工作區啟動或技能注入行為
---
# System Prompt（系統提示詞）

OpenClaw 為每次代理運行建構自訂的系統提示詞。該提示詞由 **OpenClaw 擁有**，且不使用 p-coding-agent 的預設提示詞。

提示詞由 OpenClaw 組裝並注入每次代理運行中。

## 結構

提示詞刻意保持緊湊，並使用固定的章節：

- **Tooling (工具)**：當前工具列表 + 簡短描述。
- **Skills (技能)**（可用時）：告訴模型如何按需載入技能說明。
- **OpenClaw Self-Update (自我更新)**：如何運行 `config.apply` 和 `update.run`。
- **Workspace (工作區)**：工作目錄 (`agents.defaults.workspace`)。
- **Documentation (文檔)**：OpenClaw 文檔的本地路徑（儲存庫或 npm 套件）以及何時閱讀。
- **Workspace Files (注入的工作區檔案)**：表示啟動檔案已包含於下方。
- **Sandbox (沙盒)**（啟用時）：表示沙盒化執行時間、沙盒路徑，以及是否提供提升的執行權限。
- **Current Date & Time (目前日期與時間)**：使用者本地時間、時區和時間格式。
- **Reply Tags (回覆標記)**：支援的供應商的可選回覆標記語法。
- **Heartbeats (心跳)**：心跳提示詞和確認行為。
- **Runtime (執行時間)**：主機、作業系統、節點、模型、儲存庫根目錄（偵測到時）、思考等級（單行）。
- **Reasoning (推理)**：目前的能見度等級 + `/reasoning` 切換提示。

## 提示詞模式

OpenClaw 可以為子代理生成較小的系統提示詞。執行時間會為每次運行設定一個 `promptMode`（非面對使用者的設定）：

- `full`（預設）：包含上述所有章節。
- `minimal`：用於子代理；省略 **Skills (技能)**、**Memory Recall (記憶回溯)**、**OpenClaw Self-Update (自我更新)**、**Model Aliases (模型別名)**、**User Identity (使用者身份)**、**Reply Tags (回覆標記)**、**Messaging (傳訊)**、**Silent Replies (靜默回覆)** 和 **Heartbeats (心跳)**。工具、工作區、沙盒、目前日期與時間（已知時）、執行時間和注入的上下文保持可用。
- `none`：僅返回基本的身份描述。

當 `promptMode=minimal` 時，額外注入的提示詞會被標記為 **Subagent Context (子代理上下文)**，而非 **Group Chat Context (群組聊天上下文)**。

## 工作區啟動注入 (Workspace Bootstrap Injection)

啟動檔案會被修剪並附加在 **Project Context (專案上下文)** 下，使模型無需顯式讀取即可看到身份和個人檔案上下文：

- `AGENTS.md`
- `SOUL.md`
- `TOOLS.md`
- `IDENTITY.md`
- `USER.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md`（僅限全新工作區）

大型檔案會被截斷並附帶標記。每個檔案的最大大小由 `agents.defaults.bootstrapMaxChars` 控制（預設：20000）。缺失的檔案會注入一個簡短的缺失檔案標記。

內部 hook 可以透過 `agent:bootstrap` 攔截此步驟，以修改或替換注入的啟動檔案（例如將 `SOUL.md` 換成另一個性格）。

要檢查每個注入檔案貢獻了多少（原始 vs 注入、截斷，以及工具 schema 的開銷），請使用 `/context list` 或 `/context detail`。請參閱 [Context (上下文)](/concepts/context)。

## 時間處理

當已知使用者時區時，系統提示詞包含一個專用的 **Current Date & Time (目前日期與時間)** 章節。為了保持提示詞快取的穩定性，現在僅包含**時區**（無動態時鐘或時間格式）。

當代理需要目前時間時，請使用 `session_status`；狀態資訊卡包含一個時間戳記。

透過以下設定：

- `agents.defaults.userTimezone`
- `agents.defaults.timeFormat` (`auto` | `12` | `24`)

請參閱 [Date & Time (日期與時間)](/date-time) 了解完整的行為細節。

## 技能 (Skills)

當存在符合條件的技能時，OpenClaw 會注入一個緊湊的**可用技能列表** (`formatSkillsForPrompt`)，其中包含每個技能的**檔案路徑**。提示詞引導模型使用 `read` 於所列位置（工作區、受管理或綁定）載入 SKILL.md。如果沒有符合條件的技能，則省略「技能」章節。

```
<available_skills>
  <skill>
    <name>...</name>
    <description>...</description>
    <location>...</location>
  </skill>
</available_skills>
```

這在保持基礎提示詞精簡的同時，仍能實現有針對性的技能使用。

## 文檔 (Documentation)

可用時，系統提示詞包含一個 **Documentation (文檔)** 章節，指向本地 OpenClaw 文檔目錄（儲存庫工作區中的 `docs/` 或綁定的 npm 套件文檔），並註明公共鏡像、原始程式碼儲存庫、社群 Discord 和用於發現技能的 ClawdHub (https://clawdhub.com)。提示詞引導模型首先諮詢本地文檔以了解 OpenClaw 的行為、命令、設定或架構，並在可能的情況下自行執行 `openclaw status`（僅在缺乏存取權限時才詢問使用者）。
