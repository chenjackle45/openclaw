---
summary: "在 OpenClaw 中使用 Amazon Bedrock (Converse API) 模型"
read_when:
  - You want to use Amazon Bedrock models with OpenClaw
  - You need AWS credential/region setup for model calls
title: "Amazon Bedrock"
---

# Amazon Bedrock

OpenClaw 可以透過 pi-ai 的 **Bedrock Converse** 串流提供者使用 **Amazon Bedrock** 模型。Bedrock 驗證使用 **AWS SDK 預設認證鏈**，而不是 API 金鑰。

## pi-ai 支援的功能

- 提供者：`amazon-bedrock`
- API：`bedrock-converse-stream`
- 驗證：AWS 認證（環境變數、共享設定或執行個體角色）
- 地區：`AWS_REGION` 或 `AWS_DEFAULT_REGION`（預設：`us-east-1`）

## 自動模型探索

如果檢測到 AWS 認證，OpenClaw 可以自動探索支援**串流**和**文字輸出**的 Bedrock 模型。探索使用 `bedrock:ListFoundationModels` 並進行快取（預設：1 小時）。

設定選項位於 `models.bedrockDiscovery` 下：

\`\`\`json5
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
\`\`\`

筆記：

- \`enabled\` 在 AWS 認證存在時預設為 \`true\`。
- \`region\` 預設為 \`AWS_REGION\` 或 \`AWS_DEFAULT_REGION\`，然後為 \`us-east-1\`。
- \`providerFilter\` 符合 Bedrock 提供者名稱（例如 \`anthropic\`）。
- \`refreshInterval\` 為秒數；設定為 \`0\` 以停用快取。
- \`defaultContextWindow\`（預設：\`32000\`）和 \`defaultMaxTokens\`（預設：\`4096\`）用於探索的模型（如果您知道模型限制，請覆蓋）。

## 上架

1. 確保 AWS 認證在**閘道主機**上可用：

\`\`\`bash
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"

# Optional:

export AWS_SESSION_TOKEN="..."
export AWS_PROFILE="your-profile"

# Optional (Bedrock API key/bearer token):

export AWS_BEARER_TOKEN_BEDROCK="..."
\`\`\`

2. 向您的設定新增 Bedrock 提供者和模型（不需要 \`apiKey\`）：

\`\`\`json5
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
\`\`\`

## EC2 執行個體角色

在執行 OpenClaw 的 EC2 執行個體上附加 IAM 角色後，AWS SDK 將自動使用執行個體中繼資料服務 (IMDS) 進行驗證。不過，OpenClaw 的認證檢測目前只檢查環境變數，不檢查 IMDS 認證。

**因應措施：** 設定 \`AWS_PROFILE=default\` 以表示 AWS 認證可用。實際驗證仍透過 IMDS 使用執行個體角色。

\`\`\`bash

# 新增到 ~/.bashrc 或您的 shell 設定檔

export AWS_PROFILE=default
export AWS_REGION=us-east-1
\`\`\`

**EC2 執行個體角色所需的 IAM 權限**：

- \`bedrock:InvokeModel\`
- \`bedrock:InvokeModelWithResponseStream\`
- \`bedrock:ListFoundationModels\`（用於自動探索）

或附加受管理的原則 \`AmazonBedrockFullAccess\`。

## 快速設定 (AWS 路徑)

\`\`\`bash

# 1. 建立 IAM 角色和執行個體設定檔

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

# 2. 附加到您的 EC2 執行個體

aws ec2 associate-iam-instance-profile \
 --instance-id i-xxxxx \
 --iam-instance-profile Name=EC2-Bedrock-Access

# 3. 在 EC2 執行個體上，啟用探索

openclaw config set models.bedrockDiscovery.enabled true
openclaw config set models.bedrockDiscovery.region us-east-1

# 4. 設定因應措施環境變數

echo 'export AWS_PROFILE=default' >> ~/.bashrc
echo 'export AWS_REGION=us-east-1' >> ~/.bashrc
source ~/.bashrc

# 5. 驗證模型已探索

openclaw models list
\`\`\`

## 筆記

- Bedrock 需要在您的 AWS 帳戶 / 地區啟用**模型存取**。
- 自動探索需要 \`bedrock:ListFoundationModels\` 權限。
- 如果您使用設定檔，請在閘道主機上設定 \`AWS_PROFILE\`。
- OpenClaw 按以下順序顯示認證來源：\`AWS_BEARER_TOKEN_BEDROCK\`，然後 \`AWS_ACCESS_KEY_ID\` + \`AWS_SECRET_ACCESS_KEY\`，然後 \`AWS_PROFILE\`，然後預設 AWS SDK 鏈。
- 推理支援取決於模型；檢查 Bedrock 模型卡以瞭解目前的功能。
- 如果您偏好受管理的金鑰流程，您也可以在 Bedrock 前面放置 OpenAI 相容的代理，並將其設定為 OpenAI 提供者。
