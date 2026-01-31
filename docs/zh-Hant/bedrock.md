---
title: "bedrock(Amazon Bedrock)"
summary: "在 OpenClaw 中使用 Amazon Bedrock (Converse API) 模型"
read_when:
  - 想要在 OpenClaw 中使用 Amazon Bedrock 模型時
  - 需要設定 AWS 憑證/區域以進行模型調用時
---

# Amazon Bedrock

OpenClaw 可以透過 pi‑ai 的 **Bedrock Converse** 串流供應商來使用 **Amazon Bedrock** 模型。Bedrock 認證使用 **AWS SDK 預設憑證鏈**，而非 API 金鑰。

## pi‑ai 支援的內容

- 供應商：`amazon-bedrock`
- API：`bedrock-converse-stream`
- 認證：AWS 憑證（環境變數、共享配置檔或實例角色）
- 區域：`AWS_REGION` 或 `AWS_DEFAULT_REGION`（預設：`us-east-1`）

## 自動模型探索

若偵測到 AWS 憑證，OpenClaw 可以自動發現支援**串流**與**文字輸出**的 Bedrock 模型。探索過程使用 `bedrock:ListFoundationModels` 並會進行快取（預設：1 小時）。

設定選項位於 `models.bedrockDiscovery`：

```json5
{
  models: {
    bedrockDiscovery: {
      enabled: true,
      region: "us-east-1",
      providerFilter: ["anthropic", "amazon"],
      refreshInterval: 3600,
      defaultContextWindow: 32000,
      defaultMaxTokens: 4096
    }
  }
}
```

注意：
- 當存在 AWS 憑證時，`enabled` 預設為 `true`。
- `region` 預設為 `AWS_REGION` 或 `AWS_DEFAULT_REGION`，其次為 `us-east-1`。
- `providerFilter` 匹配 Bedrock 供應商名稱（例如 `anthropic`）。
- `refreshInterval` 單位為秒；設為 `0` 以停用快取。
- `defaultContextWindow`（預設：`32000`）與 `defaultMaxTokens`（預設：`4096`）用於探索到的模型（若您知道模型限制可自行覆寫）。

## 手動設定

1) 確保 **Gateway 主機**上有可用的 AWS 憑證：

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
# 選用：
export AWS_SESSION_TOKEN="..."
export AWS_PROFILE="your-profile"
# 選用（Bedrock API 金鑰/Bearer Token）：
export AWS_BEARER_TOKEN_BEDROCK="..."
```

2) 在配置中新增 Bedrock 供應商與模型（無需 `apiKey`）：

```json5
{
  models: {
    providers: {
      "amazon-bedrock": {
        baseUrl: "https://bedrock-runtime.us-east-1.amazonaws.com",
        api: "bedrock-converse-stream",
        auth: "aws-sdk",
        models: [
          {
            id: "anthropic.claude-opus-4-5-20251101-v1:0",
            name: "Claude Opus 4.5 (Bedrock)",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 200000,
            maxTokens: 8192
          }
        ]
      }
    }
  },
  agents: {
    defaults: {
      model: { primary: "amazon-bedrock/anthropic.claude-opus-4-5-20251101-v1:0" }
    }
  }
}
```

## EC2 實例角色 (Instance Roles)

當 OpenClaw 運行於附加了 IAM 角色的 EC2 實例上時，AWS SDK 會自動使用實例元數據服務 (IMDS) 進行認證。
然而，OpenClaw 目前的憑證偵測僅檢查環境變數，不會檢查 IMDS 憑證。

**解決方案：** 設定 `AWS_PROFILE=default` 以告知系統 AWS 憑證可用。實際認證仍會透過 IMDS 使用實例角色。

```bash
# 新增至 ~/.bashrc 或您的 Shell 設定檔
export AWS_PROFILE=default
export AWS_REGION=us-east-1
```

EC2 實例角色**必要的 IAM 權限**：
- `bedrock:InvokeModel`
- `bedrock:InvokeModelWithResponseStream`
- `bedrock:ListFoundationModels`（用於自動探索）

或者附加受管策略 `AmazonBedrockFullAccess`。

**快速設定：**

```bash
# 1. 建立 IAM 角色與實例設定檔
aws iam create-role --role-name EC2-Bedrock-Access \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy --role-name EC2-Bedrock-Access \
  --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess

aws iam create-instance-profile --instance-profile-name EC2-Bedrock-Access
aws iam add-role-to-instance-profile \
  --instance-profile-name EC2-Bedrock-Access \
  --role-name EC2-Bedrock-Access

# 2. 附加至您的 EC2 實例
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=EC2-Bedrock-Access

# 3. 在 EC2 實例上啟用探索
openclaw config set models.bedrockDiscovery.enabled true
openclaw config set models.bedrockDiscovery.region us-east-1

# 4. 設定權變措施環境變數
echo 'export AWS_PROFILE=default' >> ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc

# 5. 驗證模型是否被探索到
openclaw models list
```

## 注意事項

- Bedrock 需要在您的 AWS 帳戶/區域中啟用 **Model Access**。
- 自動探索需要 `bedrock:ListFoundationModels` 權限。
- 若使用 Profile，請在 Gateway 主機上設定 `AWS_PROFILE`。
- OpenClaw 依照以下順序檢查憑證來源：`AWS_BEARER_TOKEN_BEDROCK`，接著是 `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`，然後是 `AWS_PROFILE`，最後是預設 AWS SDK 鏈。
- 推理 (Reasoning) 支援取決於模型；請查看 Bedrock 模型卡以了解當前能力。
- 若您偏好使用管理金鑰流程，也可以在 Bedrock 前放置 OpenAI 相容的代理，並將其配置為 OpenAI 供應商。
