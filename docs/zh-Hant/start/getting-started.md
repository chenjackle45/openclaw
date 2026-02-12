---
summary: "在數分鐘內安裝 OpenClaw 並執行第一個聊天。"
read_when:
  - 首次從零開始設定
  - 想要最快速的方式開始聊天
title: "Getting Started（開始使用）"
---

# 開始使用

目標：從零開始到第一個能運作的聊天，最少設定。

<Info>
最快的聊天方式：開啟 Control UI（不需要頻道設定）。執行 `openclaw dashboard`，然後在瀏覽器中聊天，或在
<Tooltip headline="Gateway host（Gateway 主機）" tip="執行 OpenClaw Gateway 服務的機器。">Gateway 主機</Tooltip>上開啟 `http://127.0.0.1:18789/`。
文件：[Dashboard](/zh-Hant/web/dashboard) 和 [Control UI](/zh-Hant/web/control-ui)。
</Info>

## 先決條件

- Node 22 或更新版本

<Tip>
如果不確定，可以用 `node --version` 檢查 Node 版本。
</Tip>

## 快速設定（CLI）

<Steps>
  <Step title="安裝 OpenClaw（建議）">
    <Tabs>
      <Tab title="macOS/Linux">
        ```bash
        curl -fsSL https://openclaw.ai/install.sh | bash
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        iwr -useb https://openclaw.ai/install.ps1 | iex
        ```
      </Tab>
    </Tabs>

    <Note>
    其他安裝方式和需求：[安裝](/zh-Hant/install)。
    </Note>

  </Step>
  <Step title="執行入門精靈">
    ```bash
    openclaw onboard --install-daemon
    ```

    精靈會設定驗證、Gateway 設定和可選的頻道。
    詳見 [入門精靈](/zh-Hant/start/wizard)。

  </Step>
  <Step title="檢查 Gateway">
    如果你已安裝服務，它應該已在執行中：

    ```bash
    openclaw gateway status
    ```

  </Step>
  <Step title="開啟 Control UI">
    ```bash
    openclaw dashboard
    ```
  </Step>
</Steps>

<Check>
如果 Control UI 載入成功，你的 Gateway 已準備好使用。
</Check>

## 可選的檢查和額外功能

<AccordionGroup>
  <Accordion title="在前景執行 Gateway">
    適合快速測試或疑難排解。

    ```bash
    openclaw gateway --port 18789
    ```

  </Accordion>
  <Accordion title="傳送測試訊息">
    需要已設定的頻道。

    ```bash
    openclaw message send --target +15555550123 --message "Hello from OpenClaw"
    ```

  </Accordion>
</AccordionGroup>

## 有用的環境變數

如果將 OpenClaw 作為服務帳戶執行或想要自訂設定/狀態位置：

- `OPENCLAW_HOME` 設定用於內部路徑解析的主目錄。
- `OPENCLAW_STATE_DIR` 覆蓋狀態目錄。
- `OPENCLAW_CONFIG_PATH` 覆蓋設定檔路徑。

完整環境變數參考：[環境變數](/zh-Hant/help/environment)。

## 深入了解

<Columns>
  <Card title="入門精靈（詳細）" href="/zh-Hant/start/wizard">
    完整 CLI 精靈參考和進階選項。
  </Card>
  <Card title="macOS 應用入門" href="/zh-Hant/start/onboarding">
    macOS 應用的首次執行流程。
  </Card>
</Columns>

## 你會獲得什麼

- 一個執行中的 Gateway
- 已設定的驗證
- 對 Control UI 的存取或已連接的頻道

## 後續步驟

- DM 安全和批准：[Pairing](/zh-Hant/channels/pairing)
- 連接更多頻道：[頻道](/zh-Hant/channels)
- 進階工作流和從來源開始：[設定](/zh-Hant/start/setup)
