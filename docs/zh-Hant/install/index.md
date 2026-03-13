---
summary: "安裝 OpenClaw — 安裝程式腳本、npm/pnpm、從原始碼、Docker 等"
read_when:
  - 您需要「開始使用」快速啟動以外的安裝方法
  - 您想要部署到雲端平台
  - 您需要更新、遷移或解除安裝
title: "Install（安裝）"
---

# 安裝

已依照[開始使用](/zh-Hant/start/getting-started)完成？您已準備就緒 — 本頁適用於其他安裝方法、特定平台說明及維護。

## 系統需求

- **[Node 24（建議）](/zh-Hant/install/node)**（Node 22 LTS，目前為 `22.16+`，仍支援以確保相容性；[安裝程式腳本](#install-methods)若沒有 Node 24 會自動安裝）
- macOS、Linux 或 Windows
- 只有從原始碼建置時才需要 `pnpm`

<Note>
在 Windows 上，我們強烈建議在 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) 下執行 OpenClaw。
</Note>

## 安裝方法

<Tip>
**安裝程式腳本**是安裝 OpenClaw 的建議方式。它在一個步驟中處理 Node 偵測、安裝和引導程序。
</Tip>

<Warning>
對於 VPS/雲端主機，盡可能避免使用第三方「1-click」市集映像。偏好使用乾淨的基礎 OS 映像（例如 Ubuntu LTS），然後自行使用安裝程式腳本安裝 OpenClaw。
</Warning>

<AccordionGroup>
  <Accordion title="安裝程式腳本" icon="rocket" defaultOpen>
    下載 CLI，透過 npm 全域安裝，並啟動引導精靈。

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
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

    就這樣 — 腳本處理 Node 偵測、安裝和引導程序。

    若要跳過引導程序只安裝二進位：

    <Tabs>
      <Tab title="macOS / Linux / WSL2">
        ```bash
        curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
        ```
      </Tab>
      <Tab title="Windows (PowerShell)">
        ```powershell
        & ([scriptblock]::Create((iwr -useb https://openclaw.ai/install.ps1))) -NoOnboard
        ```
      </Tab>
    </Tabs>

    關於所有旗標、環境變數和 CI/自動化選項，請參閱[安裝程式內部機制](/zh-Hant/install/installer)。

  </Accordion>

  <Accordion title="npm / pnpm" icon="package">
    如果您已自行管理 Node，我們建議使用 Node 24。OpenClaw 仍支援 Node 22 LTS，目前為 `22.16+`，以確保相容性：

    <Tabs>
      <Tab title="npm">
        ```bash
        npm install -g openclaw@latest
        openclaw onboard --install-daemon
        ```

        <Accordion title="sharp 建置錯誤？">
          如果您全域安裝了 libvips（在 macOS 上透過 Homebrew 很常見）且 `sharp` 失敗，請強制使用預建二進位：

          ```bash
          SHARP_IGNORE_GLOBAL_LIBVIPS=1 npm install -g openclaw@latest
          ```

          如果您看到 `sharp: Please add node-gyp to your dependencies`，請安裝建置工具（macOS：Xcode CLT + `npm install -g node-gyp`）或使用上述環境變數。
        </Accordion>
      </Tab>
      <Tab title="pnpm">
        ```bash
        pnpm add -g openclaw@latest
        pnpm approve-builds -g        # 核准 openclaw、node-llama-cpp、sharp 等
        openclaw onboard --install-daemon
        ```

        <Note>
        pnpm 需要明確核准具有建置腳本的套件。首次安裝顯示「Ignored build scripts」警告後，執行 `pnpm approve-builds -g` 並選取列出的套件。
        </Note>
      </Tab>
    </Tabs>

  </Accordion>

  <Accordion title="從原始碼" icon="github">
    適用於貢獻者或任何想從本機 checkout 執行的人。

    <Steps>
      <Step title="Clone 並建置">
        Clone [OpenClaw 儲存庫](https://github.com/openclaw/openclaw)並建置：

        ```bash
        git clone https://github.com/openclaw/openclaw.git
        cd openclaw
        pnpm install
        pnpm ui:build
        pnpm build
        ```
      </Step>
      <Step title="連結 CLI">
        讓 `openclaw` 指令全域可用：

        ```bash
        pnpm link --global
        ```

        或者，跳過連結，從儲存庫內部透過 `pnpm openclaw ...` 執行指令。
      </Step>
      <Step title="執行引導程序">
        ```bash
        openclaw onboard --install-daemon
        ```
      </Step>
    </Steps>

    更深入的開發工作流程，請參閱[設定](/zh-Hant/start/setup)。

  </Accordion>
</AccordionGroup>

## 其他安裝方法

<CardGroup cols={2}>
  <Card title="Docker" href="/zh-Hant/install/docker" icon="container">
    容器化或無頭部署。
  </Card>
  <Card title="Podman" href="/zh-Hant/install/podman" icon="container">
    無根容器：執行一次 `setup-podman.sh`，然後執行啟動腳本。
  </Card>
  <Card title="Nix" href="/zh-Hant/install/nix" icon="snowflake">
    透過 Nix 進行宣告式安裝。
  </Card>
  <Card title="Ansible" href="/zh-Hant/install/ansible" icon="server">
    自動化機群佈建。
  </Card>
  <Card title="Bun" href="/zh-Hant/install/bun" icon="zap">
    透過 Bun 執行期使用僅限 CLI。
  </Card>
</CardGroup>

## 安裝後

驗證一切正常運作：

```bash
openclaw doctor         # 檢查設定問題
openclaw status         # Gateway 狀態
openclaw dashboard      # 開啟瀏覽器 UI
```

如果您需要自訂執行期路徑，請使用：

- `OPENCLAW_HOME` 用於基於主目錄的內部路徑
- `OPENCLAW_STATE_DIR` 用於可變狀態位置
- `OPENCLAW_CONFIG_PATH` 用於設定檔位置

請參閱[環境變數](/zh-Hant/help/environment)以取得優先順序和完整詳情。

## 疑難排解：找不到 `openclaw`

<Accordion title="PATH 診斷與修復">
  快速診斷：

```bash
node -v
npm -v
npm prefix -g
echo "$PATH"
```

如果 `$(npm prefix -g)/bin`（macOS/Linux）或 `$(npm prefix -g)`（Windows）**不在**您的 `$PATH` 中，您的 shell 就無法找到全域 npm 二進位（包括 `openclaw`）。

修復 — 將其新增到您的 shell 啟動檔案（`~/.zshrc` 或 `~/.bashrc`）：

```bash
export PATH="$(npm prefix -g)/bin:$PATH"
```

在 Windows 上，將 `npm prefix -g` 的輸出新增到您的 PATH。

然後開啟新終端機（或在 zsh 中執行 `rehash` / 在 bash 中執行 `hash -r`）。
</Accordion>

## 更新 / 解除安裝

<CardGroup cols={3}>
  <Card title="更新" href="/zh-Hant/install/updating" icon="refresh-cw">
    保持 OpenClaw 最新。
  </Card>
  <Card title="遷移" href="/zh-Hant/install/migrating" icon="arrow-right">
    移至新機器。
  </Card>
  <Card title="解除安裝" href="/zh-Hant/install/uninstall" icon="trash-2">
    完全移除 OpenClaw。
  </Card>
</CardGroup>
