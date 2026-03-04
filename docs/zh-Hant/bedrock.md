---
summary: "在 OpenClaw 中使用 Amazon Bedrock（Converse API）模型"
read_when:
  - You want to use Amazon Bedrock models with OpenClaw
  - You need AWS credential/region setup for model calls
title: "Amazon Bedrock（Amazon Bedrock）"
---

# Amazon Bedrock

OpenClaw 可以透過 pi-ai 的 **Bedrock Converse**
串流提供者使用 **Amazon Bedrock** 模型。Bedrock 認證使用 **AWS SDK 預設認證鏈**，
不是 API 鑰。

## pi-ai 支援的內容

- 提供者：`amazon-bedrock`
- API：`bedrock-converse-stream`
- 認證：AWS 認證（環境變數、共用設定或實例角色）
- 區域：`AWS_REGION` 或 `AWS_DEFAULT_REGION`（預設：`us-east-1`）

## 自動模型探索

如果偵測到 AWS 認證，OpenClaw 可以自動探索支援**串流**和**文字輸出**的 Bedrock
模型。探索使用 `bedrock:ListFoundationModels` 並被快取（預設：1 小時）。

設定選項在 `models.bedrockDiscovery` 底下：

```json5
{
  models: {
    bedrockDiscovery: {
      enabled: true,
      region: "us-east-1",
      providerFilter: ["anthropic", "amazon"],
      refreshInterval: 3600,
      defaultContextWindow: 32000,
      defaultMaxTokens: 4096,
    },
  },
}
```

註記：

- `enabled` 在 AWS 認證存在時預設為 `true`。
- `region` 預設為 `AWS_REGION` 或 `AWS_DEFAULT_REGION`，然後 `us-east-1`。
- `providerFilter` 符合 Bedrock 提供者名稱（例如 `anthropic`）。
- `refreshInterval` 是秒數；設定為 `0` 停用快取。
- `defaultContextWindow`（預設：`32000`）和 `defaultMaxTokens`（預設：`4096`）
  用於探索到的模型（如果知道模型限制，則覆蓋）。

## 上線

1. 確保 AWS 認證在 **gateway 主機**上可用：

```bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
# 可選：
export AWS_SESSION_TOKEN="..."
export AWS_PROFILE="your-profile"
# 可選（Bedrock API 鑰 / bearer 令牌）：
export AWS_BEARER_TOKEN_BEDROCK="..."
```

2. 新增 Bedrock 提供者和模型到設定（不需要 `apiKey`）：

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
            id: "us.anthropic.claude-opus-4-6-v1:0",
            name: "Claude Opus 4.6 (Bedrock)",
            reasoning: true,
            input: ["text", "image"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 200000,
            maxTokens: 8192,
          },
        ],
      },
    },
  },
  agents: {
    defaults: {
      model: { primary: "amazon-bedrock/us.anthropic.claude-opus-4-6-v1:0" },
    },
  },
}
```

## EC2 實例角色

在執行 OpenClaw 的 EC2 實例上附加了 IAM 角色時，AWS SDK
將自動使用實例中繼資料服務（IMDS）進行認證。
然而，OpenClaw 的認證偵測目前只檢查環境
變數，不檢查 IMDS 認證。

**因應措施**：設定 `AWS_PROFILE=default` 以訊號 AWS 認證可用。
實際認證仍透過 IMDS 使用實例角色。

```bash
# 新增到 ~/.bashrc 或 shell 設定檔
export AWS_PROFILE=default
export AWS_REGION=us-east-1
```

**EC2 實例角色的必需 IAM 權限**：

- `bedrock:InvokeModel`
- `bedrock:InvokeModelWithResponseStream`
- `bedrock:ListFoundationModels`（用於自動探索）

或附加受管制原則 `AmazonBedrockFullAccess`。

## 快速設定（AWS 路徑）

```bash
# 1. 建立 IAM 角色和實例設定檔
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

# 2. 附加到 EC2 實例
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=EC2-Bedrock-Access

# 3. 在 EC2 實例上，啟用探索
openclaw config set models.bedrockDiscovery.enabled true
openclaw config set models.bedrockDiscovery.region us-east-1

# 4. 設定因應措施環境變數
echo 'export AWS_PROFILE=default' >> ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc

# 5. 驗證模型被探索到
openclaw models list
```

## 註記

- Bedrock 需要在 AWS 帳戶 / 區域中**啟用模型存取**。
- 自動探索需要 `bedrock:ListFoundationModels` 權限。
- 如果使用設定檔，在 gateway 主機上設定 `AWS_PROFILE`。
- OpenClaw 按此順序顯示認證來源：`AWS_BEARER_TOKEN_BEDROCK`，
  然後 `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`，然後 `AWS_PROFILE`，然後
  預設 AWS SDK 鏈。
- 推理支援取決於模型；檢查 Bedrock 模型卡以獲取
  目前的能力。
- 如果偏好受管制的鑰流程，也可以在 Bedrock 前面放置 OpenAI 相容
  的代理，並將其設定為 OpenAI 提供者。
