# Terraform — Microservices on Azure

Production-grade IaC for **N microservices** (each with optional SQL database) + React frontend across **dev / test / prod** environments on Azure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  VNet (10.x.0.0/16)                                                         │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  Subnet: App Service (10.x.1.0/24)                                  │    │
│  │                                                                     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │    │
│  │  │ orders   │  │ users    │  │ payments │  │ gateway  │  ... (N)  │    │
│  │  │ (B1/S1/  │  │ (B1/S1/  │  │ (B1/S1/  │  │ (no DB)  │           │    │
│  │  │  P1v3)   │  │  P1v3)   │  │  P1v3)   │  │          │           │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────────┘           │    │
│  └───────┼──────────────┼──────────────┼──────────────────────────────┘    │
│          │              │              │                                     │
│  ┌───────▼──────────────▼──────────────▼──────────────────────────────┐    │
│  │  Subnet: SQL (10.x.2.0/24)                                         │    │
│  │                                                                     │    │
│  │  ┌─────────────────────────────────────────────────────────────┐   │    │
│  │  │  Azure SQL Server (shared, no public access)                │   │    │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │   │    │
│  │  │  │orders-db │  │users-db  │  │payments-db│  (per service)  │   │    │
│  │  │  └──────────┘  └──────────┘  └──────────┘                  │   │    │
│  │  └─────────────────────────────────────────────────────────────┘   │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌──────────────────────┐    ┌──────────────────────────────────────────┐  │
│  │  Key Vault           │    │  Static Web App (React)                  │  │
│  │  (VNet-restricted)   │    │  REACT_APP_API_ORDERS, _USERS, _PAYMENTS │  │
│  │  N secrets (per svc) │    │  (CDN + auto-deploy from Git)            │  │
│  └──────────────────────┘    └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Resources per environment

| Resource | Dev | Test | Prod |
|----------|-----|------|------|
| App Service (per service) | B1 × 1 | S1 × 1 | P1v3 × 2 |
| SQL Database (per service) | GP_Gen5_2, 25 GB | GP_Gen5_4, 25 GB | GP_Gen5_8, 100 GB |
| SQL Server (shared) | 1 | 1 | 1 |
| Key Vault | Standard | Standard | Premium (purge protection) |
| VNet CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |

## Where to Define Your Services

**All services are defined in `environments/<env>/terraform.tfvars`** in the `microservices` map:

```hcl
microservices = {
  # Service WITH a database
  orders = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/orders-service.git"
    repo_branch       = "main"
    sql_enabled       = true
    sql_sku_name      = "GP_Gen5_2"
    sql_max_size_gb   = 25
    sql_database_name = "orders-db"
  }

  # Service WITHOUT a database (e.g. gateway, cache, notification)
  gateway = {
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/api-gateway.git"
    repo_branch       = "main"
    sql_enabled       = false
    sql_sku_name      = ""
    sql_max_size_gb   = 0
    sql_database_name = ""
  }
}
```

### To add a new service:

1. Add a new entry to the `microservices` map in each `terraform.tfvars`
2. Set `sql_enabled = true/false` depending on whether it needs a DB
3. Run `terraform plan` — Terraform will create the new App Service (+ DB if enabled)

**No changes to `main.tf` or modules needed.**

### Per-service configuration options:

| Field | Description |
|-------|-------------|
| `plan_sku` | App Service Plan SKU (B1, S1, P1v3) |
| `instance_count` | Number of instances |
| `dotnet_version` | .NET runtime (v10.0) |
| `repo_url` | Git repo for this service |
| `repo_branch` | Git branch |
| `sql_enabled` | **true** = create DB, **false** = no DB |
| `sql_sku_name` | SQL SKU (GP_Gen5_2, GP_Gen5_4, GP_Gen5_8) |
| `sql_max_size_gb` | Max DB size |
| `sql_database_name` | DB name (defaults to `<service>-db`) |

## Project Structure

```
terraform/
├── main.tf                  # Root — for_each on microservices
├── variables.tf             # Input variables (microservices map)
├── outputs.tf               # Outputs (maps per service)
├── providers.tf             # AzureRM provider
├── versions.tf              # Version constraints
├── .gitignore
├── .github/
│   └── workflows/
│       └── terraform-iac.yml  # CI/CD pipeline
├── modules/
│   ├── networking/          # VNet, subnets, NSG (shared)
│   ├── app-service/         # App Service Plan + Web App (per service)
│   ├── static-web-app/      # Static Web App (shared, all API URLs)
│   ├── sql-database/        # SQL Server + Database + Firewall (per service)
│   └── key-vault/           # Key Vault + N secrets (shared)
└── environments/
    ├── dev/
    │   ├── backend.tf
    │   └── terraform.tfvars  # ← DEFINE YOUR SERVICES HERE
    ├── test/
    │   ├── backend.tf
    │   └── terraform.tfvars
    └── prod/
        ├── backend.tf
        └── terraform.tfvars
```

## How It Works

```
terraform.tfvars
    │
    │  microservices = { orders, users, payments, gateway, ... }
    │
    ▼
main.tf
    │
    ├── local.services_with_sql  ← filters: only services with sql_enabled = true
    │
    ├── module "networking"      ← 1× (shared VNet + subnets)
    ├── module "sql"             ← for_each = services_with_sql (N databases, 1 server)
    ├── module "key_vault"       ← 1× (shared, N secrets for services with SQL)
    ├── module "api"             ← for_each = ALL microservices (N App Services)
    └── module "frontend"        ← 1× (shared, gets all API URLs)
```

**Key behaviors:**
- Service with `sql_enabled = true` → gets App Service + SQL Database + Key Vault secret
- Service with `sql_enabled = false` → gets App Service only (no DB, no secret)
- Frontend gets `REACT_APP_API_<SERVICE_NAME>` for **every** service
- SQL Server is shared (one server, many databases)

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Terraform | ≥ 1.6.0 | `~> 1.9` recommended |
| AzureRM Provider | ~> 5.0 | Auto-installed by `terraform init` |
| Azure CLI | ≥ 2.50 | For SPN setup, Key Vault access |
| GitHub | — | Repo + PAT for Static Web App |
| Azure Subscription | MSDN / PAYG | Northeurope (default) |

## Quick Start (Local)

### 1. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Create Backend Storage (one-time)

```bash
az storage account create \
  --name tfstate$(openssl rand -hex 4) \
  --resource-group rg-tf-state \
  --location northeurope \
  --sku Standard_LRS

az storage container create \
  --name terraform-state \
  --account-name <your-storage-account>
```

### 3. Init & Plan

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

### 4. Apply

```bash
terraform apply -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Only-Pass-123!"
```

### 5. Verify

```bash
terraform output
# → api_domains = { orders = "orders-dotnetapi-dev.azurewebsites.net", ... }
# → sql_databases = { orders = "/subscriptions/.../orders-db", ... }
# → frontend_url = "fe-dotnetapi-dev.azurestaticapps.net"
```

### 6. Destroy

```bash
terraform destroy -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Only-Pass-123!"
```

## Pipeline (GitHub Actions)

### Setup (one-time)

#### Azure — OIDC Federation

```bash
az ad app create \
  --display-name "GitHub Actions OIDC" \
  --reply-urls "https://token.actions.githubusercontent.com"

az ad app federated-credential create \
  --id <app-object-id> \
  --source-provider oidc \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:your-org/your-repo:ref:refs/heads/main"

az ad sp create --id <app-object-id>
```

#### GitHub — Repository Secrets

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App Registration Object ID |
| `AZURE_TENANT_ID` | Your Azure Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `AZURE_SPN_CREDENTIALS` | JSON from `az ad sp create-for-rbac --sdk-auth` |
| `AZURE_STORAGE_ACCOUNT` | Backend storage account name |
| `FRONTEND_REPO_TOKEN` | GitHub PAT (repo scope) |
| `SQL_ADMIN_PASSWORD` | SQL admin password |

#### GitHub — Environments

1. Settings → Environments → create: `dev`, `test`, `prod`
2. For `prod`: add **Required reviewers**

### Pipeline Flow

```
MR (changes to *.tf)
  → format → validate → plan [dev, test, prod] → upload artifact
  (NO APPLY)

Push to main
  → format → validate → plan → apply [dev, test, prod]
  (prod requires manual approval)
```

## Security Model

| Concern | Mitigation |
|---------|-----------|
| SQL public access | **Disabled** — VNet-only via service endpoint |
| Key Vault network | **Deny all** + allow only App Service subnet |
| App Service | VNet Integration (private IP) |
| TLS | Minimum 1.2 everywhere |
| Secrets | `sensitive = true`, never in git |
| Pipeline auth | OIDC (no long-lived credentials) |
| Prod apply | Manual approval (GitHub Environments) |
| State | Remote (Azure Blob) + state locking |
| Purge protection | Key Vault: prod only |

## Key Design Decisions

1. **`for_each` on microservices map** — add/remove services by editing tfvars only
2. **`sql_enabled` flag** — services without DB don't create SQL resources
3. **Shared SQL Server** — one server, N databases (cheaper, simpler firewall)
4. **Shared Key Vault** — one vault, N secrets (one access policy to manage)
5. **Shared VNet** — all services in one VNet (service endpoint covers all)
6. **Per-service tags** — `Service=<name>` for cost attribution
7. **Frontend gets all URLs** — `REACT_APP_API_<NAME>` per service
8. **Random suffix** — globally-unique names for KV, SQL Server

## Scaling to 100+ Services

The architecture scales linearly:

- **100 services** = 100 App Services + up to 100 Databases + 100 Key Vault secrets
- **Azure limits to watch:**
  - App Service: 100 per subscription per region (request increase)
  - SQL Databases: 500 per server (request increase)
  - Key Vault secrets: 10,000 per vault (plenty)
  - VNet IPs: /16 = 65,536 (plenty for 100 services)
- **Cost:** scales linearly. Use `plan_sku = "B1"` for non-critical services in dev.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Error: No valid credential sources` | `az login` or check SPN creds |
| `Error: Backend initialization required` | `terraform init` with backend-config |
| `Error: quota exceeded` | Azure portal → request quota increase |
| `Error: subnet delegation` | Handled in networking module |
| VS Code false warnings | `Ctrl+Shift+P` → "Terraform: Force Language Server Restart" |
| `Error: lock info` | `terraform force-unlock <LOCK_ID>` |

## Cost Estimation (approximate, Northeurope, 4 services)

| Env | Monthly (est.) |
|-----|---------------|
| Dev (4× B1 + 3× GP_Gen5_2 + KV) | ~$120–180 |
| Test (4× S1 + 3× GP_Gen5_4 + KV) | ~$400–600 |
| Prod (4× P1v3×2 + 3× GP_Gen5_8 + KV Premium) | ~$1,500–2,500 |

> Scales linearly with number of services. Use [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/).

## Contributing

1. Fork / branch
2. Modify `terraform.tfvars` (add/remove services) or `.tf` files
3. `terraform fmt -recursive && terraform validate`
4. Open MR → pipeline runs plan
5. Review plan artifact
6. Merge → pipeline applies (prod needs approval)
