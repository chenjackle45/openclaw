---
summary: "在 Azure Linux VM 上執行 OpenClaw Gateway 24/7，具備持久狀態"
read_when:
  - 你想要在 Azure 上執行 OpenClaw 24/7 並加強網路安全群組
  - 你想要在自己的 Azure Linux VM 上執行生產級、始終開啟的 OpenClaw Gateway
  - 你想要使用 Azure Bastion SSH 進行安全的管理
title: "Azure"
---

# OpenClaw on Azure Linux VM

本指南設定了 Azure Linux VM，安裝 Azure CLI、套用網路安全群組 (NSG) 強化、配置 Azure Bastion 進行 SSH 存取，並安裝 OpenClaw。

## 你將進行的操作

- 使用 Azure CLI 建立 Azure 網路 (VNet、子網路、NSG) 和運算資源
- 套用網路安全群組規則，使 VM SSH 只允許來自 Azure Bastion
- 使用 Azure Bastion 進行 SSH 存取（VM 上無公開 IP）
- 使用安裝程式腳本安裝 OpenClaw
- 驗證 Gateway

## 你需要的

- 具有建立運算和網路資源權限的 Azure 訂用帳戶
- 已安裝 Azure CLI（若需要，詳見 [Azure CLI 安裝步驟](https://learn.microsoft.com/cli/azure/install-azure-cli)）
- SSH 金鑰組（本指南涵蓋了產生一對金鑰的步驟）
- 約 20-30 分鐘

## 配置部署

<Steps>
  <Step title="登入 Azure CLI">
    ```bash
    az login
    az extension add -n ssh
    ```

    `ssh` 擴充程式是 Azure Bastion 原生 SSH 通道所必需的。

  </Step>

  <Step title="登錄所需的資源提供者（一次性）">
    ```bash
    az provider register --namespace Microsoft.Compute
    az provider register --namespace Microsoft.Network
    ```

    驗證登錄。等到兩者都顯示 `Registered`。

    ```bash
    az provider show --namespace Microsoft.Compute --query registrationState -o tsv
    az provider show --namespace Microsoft.Network --query registrationState -o tsv
    ```

  </Step>

  <Step title="設定部署變數">
    ```bash
    RG="rg-openclaw"
    LOCATION="westus2"
    VNET_NAME="vnet-openclaw"
    VNET_PREFIX="10.40.0.0/16"
    VM_SUBNET_NAME="snet-openclaw-vm"
    VM_SUBNET_PREFIX="10.40.2.0/24"
    BASTION_SUBNET_PREFIX="10.40.1.0/26"
    NSG_NAME="nsg-openclaw-vm"
    VM_NAME="vm-openclaw"
    ADMIN_USERNAME="openclaw"
    BASTION_NAME="bas-openclaw"
    BASTION_PIP_NAME="pip-openclaw-bastion"
    ```

    調整名稱和 CIDR 範圍以符合你的環境。Bastion 子網路必須至少是 `/26`。

  </Step>

  <Step title="選擇 SSH 金鑰">
    如果你有現有的公開金鑰，請使用它：

    ```bash
    SSH_PUB_KEY="$(cat ~/.ssh/id_ed25519.pub)"
    ```

    如果你還沒有 SSH 金鑰，產生一個：

    ```bash
    ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -C "you@example.com"
    SSH_PUB_KEY="$(cat ~/.ssh/id_ed25519.pub)"
    ```

  </Step>

  <Step title="選擇 VM 大小和 OS 磁碟大小">
    ```bash
    VM_SIZE="Standard_B2as_v2"
    OS_DISK_SIZE_GB=64
    ```

    選擇你的訂用帳戶和區域中可用的 VM 大小和 OS 磁碟大小：

    - 輕度使用時從較小的大小開始，之後再擴充
    - 使用更多 vCPU/RAM/磁碟用於較重的自動化、更多頻道或較大的模型/工具工作負載
    - 如果 VM 大小在你的區域或訂用帳戶配額中無法使用，請選擇最接近的可用 SKU

    列出目標區域中可用的 VM 大小：

    ```bash
    az vm list-skus --location "${LOCATION}" --resource-type virtualMachines -o table
    ```

    檢查你目前的 vCPU 和磁碟使用量/配額：

    ```bash
    az vm list-usage --location "${LOCATION}" -o table
    ```

  </Step>
</Steps>

## 部署 Azure 資源

<Steps>
  <Step title="建立資源群組">
    ```bash
    az group create -n "${RG}" -l "${LOCATION}"
    ```
  </Step>

  <Step title="建立網路安全群組">
    建立 NSG 並新增規則，使只有 Bastion 子網路可以 SSH 進入 VM。

    ```bash
    az network nsg create \
      -g "${RG}" -n "${NSG_NAME}" -l "${LOCATION}"

    # 允許來自 Bastion 子網路的 SSH
    az network nsg rule create \
      -g "${RG}" --nsg-name "${NSG_NAME}" \
      -n AllowSshFromBastionSubnet --priority 100 \
      --access Allow --direction Inbound --protocol Tcp \
      --source-address-prefixes "${BASTION_SUBNET_PREFIX}" \
      --destination-port-ranges 22

    # 拒絕來自公開網際網路的 SSH
    az network nsg rule create \
      -g "${RG}" --nsg-name "${NSG_NAME}" \
      -n DenyInternetSsh --priority 110 \
      --access Deny --direction Inbound --protocol Tcp \
      --source-address-prefixes Internet \
      --destination-port-ranges 22

    # 拒絕來自其他 VNet 來源的 SSH
    az network nsg rule create \
      -g "${RG}" --nsg-name "${NSG_NAME}" \
      -n DenyVnetSsh --priority 120 \
      --access Deny --direction Inbound --protocol Tcp \
      --source-address-prefixes VirtualNetwork \
      --destination-port-ranges 22
    ```

    規則按優先級評估（最低編號優先）：Bastion 流量在 100 允許，然後所有其他 SSH 在 110 和 120 被阻止。

  </Step>

  <Step title="建立虛擬網路和子網路">
    建立附有 VM 子網路（NSG 已附加）的 VNet，然後新增 Bastion 子網路。

    ```bash
    az network vnet create \
      -g "${RG}" -n "${VNET_NAME}" -l "${LOCATION}" \
      --address-prefixes "${VNET_PREFIX}" \
      --subnet-name "${VM_SUBNET_NAME}" \
      --subnet-prefixes "${VM_SUBNET_PREFIX}"

    # 將 NSG 附加到 VM 子網路
    az network vnet subnet update \
      -g "${RG}" --vnet-name "${VNET_NAME}" \
      -n "${VM_SUBNET_NAME}" --nsg "${NSG_NAME}"

    # AzureBastionSubnet — Azure 需要此名稱
    az network vnet subnet create \
      -g "${RG}" --vnet-name "${VNET_NAME}" \
      -n AzureBastionSubnet \
      --address-prefixes "${BASTION_SUBNET_PREFIX}"
    ```

  </Step>

  <Step title="建立 VM">
    VM 沒有公開 IP。SSH 存取是透過 Azure Bastion 專線進行的。

    ```bash
    az vm create \
      -g "${RG}" -n "${VM_NAME}" -l "${LOCATION}" \
      --image "Canonical:ubuntu-24_04-lts:server:latest" \
      --size "${VM_SIZE}" \
      --os-disk-size-gb "${OS_DISK_SIZE_GB}" \
      --storage-sku StandardSSD_LRS \
      --admin-username "${ADMIN_USERNAME}" \
      --ssh-key-values "${SSH_PUB_KEY}" \
      --vnet-name "${VNET_NAME}" \
      --subnet "${VM_SUBNET_NAME}" \
      --public-ip-address "" \
      --nsg ""
    ```

    `--public-ip-address ""` 防止指派公開 IP。`--nsg ""` 略過建立個別 NIC NSG（子網路級別 NSG 處理安全性）。

    **重現性：** 上述命令針對 Ubuntu 映像使用 `latest`。若要固定特定版本，列出可用版本並取代 `latest`：

    ```bash
    az vm image list \
      --publisher Canonical --offer ubuntu-24_04-lts \
      --sku server --all -o table
    ```

  </Step>

  <Step title="建立 Azure Bastion">
    Azure Bastion 為 VM 提供管理的 SSH 存取，無需暴露公開 IP。CLI 型 `az network bastion ssh` 需要標準 SKU 與通道。

    ```bash
    az network public-ip create \
      -g "${RG}" -n "${BASTION_PIP_NAME}" -l "${LOCATION}" \
      --sku Standard --allocation-method Static

    az network bastion create \
      -g "${RG}" -n "${BASTION_NAME}" -l "${LOCATION}" \
      --vnet-name "${VNET_NAME}" \
      --public-ip-address "${BASTION_PIP_NAME}" \
      --sku Standard --enable-tunneling true
    ```

    Bastion 佈建通常需要 5-10 分鐘，但在某些區域可能需要 15-30 分鐘。

  </Step>
</Steps>

## 安裝 OpenClaw

<Steps>
  <Step title="透過 Azure Bastion SSH 進入 VM">
    ```bash
    VM_ID="$(az vm show -g "${RG}" -n "${VM_NAME}" --query id -o tsv)"

    az network bastion ssh \
      --name "${BASTION_NAME}" \
      --resource-group "${RG}" \
      --target-resource-id "${VM_ID}" \
      --auth-type ssh-key \
      --username "${ADMIN_USERNAME}" \
      --ssh-key ~/.ssh/id_ed25519
    ```

  </Step>

  <Step title="安裝 OpenClaw（在 VM 殼層中）">
    ```bash
    curl -fsSL https://openclaw.ai/install.sh -o /tmp/install.sh
    bash /tmp/install.sh
    rm -f /tmp/install.sh
    ```

    安裝程式會在不存在時安裝 Node LTS 和相依性、安裝 OpenClaw，並啟動上線嚮導。詳見 [安裝](/zh-Hant/install)。

  </Step>

  <Step title="驗證 Gateway">
    上線完成後：

    ```bash
    openclaw gateway status
    ```

    大多數企業 Azure 團隊已經有 GitHub Copilot 授權。如果是你的情況，我們建議在 OpenClaw 上線嚮導中選擇 GitHub Copilot 提供者。詳見 [GitHub Copilot 提供者](/zh-Hant/providers/github-copilot)。

  </Step>
</Steps>

## 成本考慮

Azure Bastion 標準 SKU 執行費用約為 **$140/月**，VM (Standard_B2as_v2) 執行費用約為 **$55/月**。

降低成本的方式：

- **未使用時解除分配 VM**（停止運算計費；磁碟費用仍然保留）。OpenClaw Gateway 在 VM 解除分配時將無法到達──需要時重新啟動：

  ```bash
  az vm deallocate -g "${RG}" -n "${VM_NAME}"
  az vm start -g "${RG}" -n "${VM_NAME}"   # 稍後重新啟動
  ```

- **不需要時刪除 Bastion**，需要 SSH 存取時重新建立。Bastion 是最大的成本元件，佈建只需幾分鐘。
- **使用基本 Bastion SKU**（約 $38/月），如果你只需要入口網站型 SSH，不需要 CLI 通道（`az network bastion ssh`）。

## 清理

刪除本指南建立的所有資源：

```bash
az group delete -n "${RG}" --yes --no-wait
```

這會移除資源群組及其內的所有內容（VM、VNet、NSG、Bastion、公開 IP）。

## 後續步驟

- 設定訊息傳遞頻道：[頻道](/zh-Hant/channels)
- 配對本機裝置為節點：[節點](/zh-Hant/nodes)
- 配置 Gateway：[Gateway 配置](/zh-Hant/gateway/configuration)
- 詳細了解 OpenClaw Azure 部署與 GitHub Copilot 模型提供者：[OpenClaw on Azure with GitHub Copilot](https://github.com/johnsonshi/openclaw-azure-github-copilot)
