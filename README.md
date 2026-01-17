# Supabase on Minikube

Local development environment for Supabase deployed on Kubernetes (Minikube).

## Prerequisites

Before running the infrastructure, ensure you have the following tools installed:

### 1. Minikube
Run Kubernetes locally.
```bash
brew install minikube
```

### 2. Helm
Package manager for Kubernetes.
```bash
brew install helm
```

### 3. Docker
Container runtime (required driver for Minikube).
[Download Docker Desktop](https://www.docker.com/products/docker-desktop/)

### 4. k9s (Optional but Recommended)
Terminal UI to manage Kubernetes clusters.
```bash
brew install k9s
```

## Quick Start

1. **Start the Infrastructure**:
   Go to the `infra` directory and use the helper script:
   ```bash
   cd infra
   ./infra.sh start
   ```

2. **Deploy Supabase**:
   Deploy the local stack with custom configuration:
   ```bash
   ./infra.sh local-stack
   ```

3. **Access Services**:
   - **Studio UI**: [http://localhost:30001](http://localhost:30001) (via Minikube IP)
   - **API Gateway**: `http://<minikube-ip>:30000`

## Management

The `infra/infra.sh` script provides easy management commands:

| Command | Description |
|---------|-------------|
| `./infra.sh start` | Start Minikube cluster |
| `./infra.sh local-stack` | Deploy/Update Supabase stack |
| `./infra.sh status` | Check deployment status |
| `./infra.sh stop` | Stop Minikube |
| `./infra.sh uninstall` | Remove Supabase deployment |

## Troubleshooting

If you encounter issues (e.g., ImagePullBackOff, missing secrets):
1. Uninstall the release: `./infra.sh uninstall`
2. Redeploy: `./infra.sh local-stack`
3. Check pod status with `k9s` or `kubectl get pods -n supabase`
