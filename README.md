# Terraform — .NET 10 API + React Frontend on Azure

Production-grade IaC for a 3-tier application (API, Frontend, Database) across **dev / test / prod** environments on Azure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  VNet (10.x.0.0/16)                                                 │
│                                                                     │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐  │
│  │  Subnet: App Service  │    │  Subnet: SQL                     │  │
│  │  10.x.1.0/24         │    │  10.x.2.0/24                     │  │
│  │                       │    │                                  │  │
│  │  ┌─────────────────┐  │    │  ┌────────────────────────────┐  │  │
│  │  │  App Service     │  │    │  │  Azure SQL Database        │  │  │
│  │  │  (.NET 10 API)   │  │    │  │  (GP_Gen5, no public acc) │  │  │
│  │  │  VNet Integration│  │    │  └────────────────────────────┘  │  │
│  │  └─────────────────┘  │    └──────────────────────────────────┘  │
│  └──────────────────────┘                                         │
│                                                                     │
│  ┌──────────────────────┐    ┌──────────────────────────────────┐  │
│  │  Key Vault           │    │  Static Web App (React)          │  │
│  │  (VNet-restricted)   │    │  (CDN + auto-deploy from Git)    │  │
│  └──────────────────────┘    └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Resources per environment

| Resource | Dev | Test | Prod |
|----------|-----|------|------|
| App Service Plan | B1 × 1 | S1 × 1 | P1v3 × 2 |
| SQL Database | GP_Gen5_2, 25 GB | GP_Gen5_4, 25 GB | GP_Gen5_8, 100 GB |
| Key Vault | Standard | Standard | Premium (purge protection) |
| VNet CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |

## Project Structure

```
terraform/
├── main.tf                  # Root module — wires everything together
├── variables.tf             # Input variables (with validation)
├── outputs.tf               # Root outputs
├── providers.tf             # AzureRM provider + features block
├── versions.tf              # Terraform + provider version constraints
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform-iac.yml  # CI/CD pipeline
├── modules/
│   ├── networking/          # VNet, subnets, NSG
│   ├── app-service/         # App Service Plan + Linux Web App (.NET 10)
│   ├── static-web-app/      # Static Web App (React + CDN)
│   ├── sql-database/        # SQL Server + Database + Firewall
│   └── key-vault/           # Key Vault + Access Policies + Secrets
└── environments/
    ├── dev/
    │   ├── backend.tf       # Remote backend (blob: dev/terraform.tfstate)
    │   └── terraform.tfvars # Dev-specific values
    ├── test/
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tf
        └── terraform.tfvars
```

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Terraform | ≥ 1.6.0 | `~> 1.9` recommended |
| AzureRM Provider | ~> 5.0 | Auto-installed by `terraform init` |
| Azure CLI | ≥ 2.50 | For SPN setup, Key Vault access |
| GitHub | — | Repo + PAT for Static Web App |
| Azure Subscription | MSDN / PAYG | Northeurope (default) |

## Quick Start (Local)

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Create Backend Storage Account (one-time)

```bash
# Create a storage account for Terraform state (separate from app resources)
az storage account create \
  --name tfstate$(openssl rand -hex 4) \
  --resource-group rg-tf-state \
  --location northeurope \
  --sku Standard_LRS

az storage container create \
  --name terraform-state \
  --account-name <your-storage-account>
```

### 3. Create Service Principal (for pipeline)

```bash
az ad sp create-for-rbac \
  --name "tf-iac-spn" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth > spn-credentials.json
```

### 4. Init & Plan (Dev)

```bash
cd environments/dev

terraform init \
  -backend-config="storage_account_name=<your-storage-account>" \
  -backend-config="container_name=terraform-state" \
  -backend-config="key=dev/terraform.tfstate"

terraform plan -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Only-Pass-123!"
```

### 5. Apply

```bash
terraform apply -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Only-Pass-123!"
```

### 6. Verify

```bash
terraform output
# → api_default_domain, frontend_url, key_vault_uri, etc.
```

### 7. Destroy (when done testing)

```bash
terraform destroy -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Only-Pass-123!"
```

## Pipeline (GitHub Actions)

### Setup (one-time)

#### Azure — OIDC Federation

```bash
# 1. Get your GitHub App ID (from Azure Portal → App Registrations → GitHub Actions)
#    Or create one:
az ad app create \
  --display-name "GitHub Actions OIDC" \
  --reply-urls "https://token.actions.githubusercontent.com"

# 2. Create federated credential
az ad app federated-credential create \
  --id <app-object-id> \
  --source-provider oidc \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:your-org/your-repo:ref:refs/heads/main"

# 3. Create SPN for the app (if not already)
az ad sp create --id <app-object-id>
```

#### GitHub — Repository Secrets

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App Registration Object ID |
| `AZURE_TENANT_ID` | Your Azure Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `AZURE_SPN_CREDENTIALS` | JSON from `az ad sp create-for-rbac --sdk-auth` (for MRs) |
| `AZURE_STORAGE_ACCOUNT` | Backend storage account name |
| `FRONTEND_REPO_TOKEN` | GitHub PAT (repo scope) for Static Web App |
| `SQL_ADMIN_PASSWORD` | SQL admin password (rotate via Key Vault in prod) |

#### GitHub — Environments (manual approval)

1. Go to **Settings → Environments**
2. Create: `dev`, `test`, `prod`
3. For `prod`: add **Required reviewers** (yourself / team lead)
4. Optionally add **wait timers** for prod

### Pipeline Flow

```
MR opened (changes to *.tf)
  │
  ├─→ format (terraform fmt -check)
  ├─→ validate (terraform validate)
  └─→ plan [dev, test, prod] ──→ upload tfplan artifact
                                  (NO APPLY on MR)

Push to main
  │
  ├─→ format
  ├─→ validate
  ├─→ plan [dev, test, prod]
  └─→ apply [dev, test, prod]
       └─ prod requires manual approval (GitHub Environment)
```

## Security Model

| Concern | Mitigation |
|---------|-----------|
| SQL public access | **Disabled** — VNet-only via service endpoint |
| Key Vault network | **Deny all** + allow only App Service subnet |
| App Service | VNet Integration (private IP) |
| TLS | Minimum 1.2 everywhere |
| Secrets in state | `sensitive = true` on variables; never in git |
| Pipeline auth | OIDC (no long-lived credentials) |
| Prod apply | Manual approval via GitHub Environments |
| State file | Remote (Azure Blob) + state locking |
| Purge protection | Key Vault: enabled in prod only |

## Key Design Decisions

1. **One root module, multiple environments** — same code, different `tfvars`. No copy-paste.
2. **Remote state per env** — `dev/terraform.tfstate`, `test/...`, `prod/...` in one storage account.
3. **VNet per env** — no cross-env traffic, isolated CIDR blocks.
4. **No public SQL** — service endpoint + firewall rule for App Service subnet only.
5. **Static Web App over CDN** — Azure SWA gives you CDN + auto-deploy + custom domain in one resource.
6. **Random suffix** — globally-unique names for KV, SQL Server (Azure requirement).
7. **Tags everywhere** — `Environment`, `Project`, `ManagedBy`, `CostCenter` for cost tracking.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Error: No valid credential sources found` | `az login` or check SPN creds |
| `Error: Backend initialization required` | Run `terraform init` with backend-config |
| `Error: quota exceeded` | Azure portal → request quota increase for region |
| `Error: subnet delegation` | App Service subnet needs delegation to `Microsoft.Web/serverFarms` (handled in module) |
| VS Code shows false warnings | `Ctrl+Shift+P` → "Terraform: Force Language Server Restart" |
| `Error: lock info` | Someone else has the state locked — wait or `terraform force-unlock` |

## Cost Estimation (approximate, Northeurope)

| Env | Monthly (est.) |
|-----|---------------|
| Dev (B1 + GP_Gen5_2 + KV Standard) | ~$40–60 |
| Test (S1 + GP_Gen5_4 + KV Standard) | ~$120–180 |
| Prod (P1v3×2 + GP_Gen5_8 + KV Premium) | ~$400–600 |

> Actual costs depend on usage. Use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for precise estimates.

## Contributing

1. Fork / branch
2. Modify `.tf` files
3. `terraform fmt -recursive && terraform validate`
4. Open MR → pipeline runs plan automatically
5. Review plan artifact
6. Merge → pipeline applies to all envs (prod needs approval)
