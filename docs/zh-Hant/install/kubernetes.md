---
summary: "使用 Kustomize 將 OpenClaw Gateway 部署到 Kubernetes 叢集"
read_when:
  - 您想在 Kubernetes 叢集上執行 OpenClaw
  - 您想在 Kubernetes 環境測試 OpenClaw
title: "Kubernetes"
---

# OpenClaw on Kubernetes

在 Kubernetes 上執行 OpenClaw 的最小起點 — 不是生產就緒部署。它涵蓋核心資源且旨在適應您的環境。

## 為什麼不用 Helm？

OpenClaw 是一個容器加一些配置檔案。有趣的自訂在代理內容（markdown 檔案、skills、配置覆蓋），不在基礎設施樣板化。Kustomize 無需 Helm 圖表的額外開銷即可處理覆蓋。如果您的部署變得更複雜，Helm 圖表可以分層到這些清單之上。

## 您需要什麼

- 執行中的 Kubernetes 叢集（AKS、EKS、GKE、k3s、kind、OpenShift 等）
- `kubectl` 連接到您的叢集
- 至少一個模型提供者的 API 金鑰

## 快速開始

```bash
# 以您的提供者替換：ANTHROPIC、GEMINI、OPENAI 或 OPENROUTER
export <PROVIDER>_API_KEY="..."
./scripts/k8s/deploy.sh

kubectl port-forward svc/openclaw 18789:18789 -n openclaw
open http://localhost:18789
```

檢索 Gateway 令牌並將其貼入控制 UI：

```bash
kubectl get secret openclaw-secrets -n openclaw -o jsonpath='{.data.OPENCLAW_GATEWAY_TOKEN}' | base64 -d
```

用於本地除錯，`./scripts/k8s/deploy.sh --show-token` 在部署後列印令牌。

## 使用 Kind 進行本地測試

如果您沒有叢集，用 [Kind](https://kind.sigs.k8s.io/) 在本地建立一個：

```bash
./scripts/k8s/create-kind.sh           # 自動偵測 docker 或 podman
./scripts/k8s/create-kind.sh --delete  # 拆除
```

然後如常用 `./scripts/k8s/deploy.sh` 部署。

## 逐步進行

### 1) 部署

**選項 A** — 環境中的 API 金鑰（一步）：

```bash
# 以您的提供者替換：ANTHROPIC、GEMINI、OPENAI 或 OPENROUTER
export <PROVIDER>_API_KEY="..."
./scripts/k8s/deploy.sh
```

指令碼使用 API 金鑰和自動產生的 Gateway 令牌建立 Kubernetes Secret，然後部署。如果 Secret 已存在，它保留當前 Gateway 令牌和任何未變更的提供者金鑰。

**選項 B** — 分別建立 Secret：

```bash
export <PROVIDER>_API_KEY="..."
./scripts/k8s/deploy.sh --create-secret
./scripts/k8s/deploy.sh
```

使用任一命令的 `--show-token` 若要令牌列印至 stdout 以進行本地測試。

### 2) 存取 Gateway

```bash
kubectl port-forward svc/openclaw 18789:18789 -n openclaw
open http://localhost:18789
```

## 部署內容

```
命名空間：openclaw（可通過 OPENCLAW_NAMESPACE 配置）
├── Deployment/openclaw        # 單一 Pod、init 容器 + Gateway
├── Service/openclaw           # ClusterIP 埠 18789
├── PersistentVolumeClaim      # 10Gi 代理狀態和配置
├── ConfigMap/openclaw-config  # openclaw.json + AGENTS.md
└── Secret/openclaw-secrets    # Gateway 令牌 + API 金鑰
```

## 自訂

### 代理指令

在 `scripts/k8s/manifests/configmap.yaml` 中編輯 `AGENTS.md` 並重新部署：

```bash
./scripts/k8s/deploy.sh
```

### Gateway 配置

在 `scripts/k8s/manifests/configmap.yaml` 中編輯 `openclaw.json`。詳見 [Gateway 配置](/zh-Hant/gateway/configuration)。

### 添加提供者

以額外金鑰匯出重新執行：

```bash
export ANTHROPIC_API_KEY="..."
export OPENAI_API_KEY="..."
./scripts/k8s/deploy.sh --create-secret
./scripts/k8s/deploy.sh
```

現有提供者金鑰保留在 Secret 中，除非您覆蓋它們。

或直接修補 Secret：

```bash
kubectl patch secret openclaw-secrets -n openclaw \
  -p '{"stringData":{"<PROVIDER>_API_KEY":"..."}}'
kubectl rollout restart deployment/openclaw -n openclaw
```

### 自訂命名空間

```bash
OPENCLAW_NAMESPACE=my-namespace ./scripts/k8s/deploy.sh
```

### 自訂映像

在 `scripts/k8s/manifests/deployment.yaml` 中編輯 `image` 欄位：

```yaml
image: ghcr.io/openclaw/openclaw:2026.3.1
```

### 超越 port-forward 的暴露

預設清單將 Gateway 綁定至 Pod 內的 loopback。這對 `kubectl port-forward` 有效，但對於需要達到 Pod IP 的 Kubernetes `Service` 或 Ingress 路徑無效。

如果您想通過 Ingress 或負載均衡器暴露 Gateway：

- 在 `scripts/k8s/manifests/configmap.yaml` 中將 Gateway 綁定從 `loopback` 改為符合您部署模型的非 loopback 綁定
- 保持 Gateway 驗證啟用且使用適當的 TLS 終止端點
- 為遠端存取配置控制 UI 使用支援的 web 安全模型（例如 HTTPS/Tailscale Serve 和當需要時明確允許來源）

## 重新部署

```bash
./scripts/k8s/deploy.sh
```

這應用所有清單並重啟 Pod 以拾取任何配置或 Secret 變更。

## 拆除

```bash
./scripts/k8s/deploy.sh --delete
```

這刪除命名空間和其中的所有資源，包括 PVC。

## 架構附註

- Gateway 預設綁定至 Pod 內的 loopback，所以包含的設定用於 `kubectl port-forward`
- 無叢集範圍資源 — 所有內容生活在單一命名空間
- 安全性：`readOnlyRootFilesystem`、`drop: ALL` 能力、非根使用者 (UID 1000)
- 預設配置保持控制 UI 在更安全的本地存取路徑：loopback 綁定加 `kubectl port-forward` 至 `http://127.0.0.1:18789`
- 如果您超越 localhost 存取，使用支援遠端模型：HTTPS/Tailscale 加適當的 Gateway 綁定和控制 UI 源設定
- Secret 在臨時目錄中產生並直接應用至叢集 — 無 Secret 材料寫入儲存庫簽出

## 檔案結構

```
scripts/k8s/
├── deploy.sh                   # 建立命名空間 + Secret，通過 kustomize 部署
├── create-kind.sh              # 本地 Kind 叢集（自動偵測 docker/podman）
└── manifests/
    ├── kustomization.yaml      # Kustomize 基礎
    ├── configmap.yaml          # openclaw.json + AGENTS.md
    ├── deployment.yaml         # 含安全加固的 Pod 規格
    ├── pvc.yaml                # 10Gi 持久儲存
    └── service.yaml            # 埠 18789 上的 ClusterIP
```
