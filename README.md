<div align="center">

# terraform-skeleton

**A sample Terraform project for deploying .NET microservices on Azure**

[![Terraform](https://img.shields.io/badge/terraform-1.9+-8C14F5?logo=hashicorp&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Azure](https://img.shields.io/badge/azure-5.4+-0078D4?logo=microsoftazure&logoColor=white)](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

</div>

---

A reference skeleton showing how to structure a multi-environment Terraform project for a microservices architecture on Azure. Clone it, make it your own, and point it at your repos.

**What it does:** deploys N .NET 10 microservices (each with an optional SQL database) + a React frontend across dev / test / prod. You wire up your own CI/CD — the structure is here, the pipeline is yours to build.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  VNet (10.x.0.0/16)                                                     │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  Subnet: App Service (10.x.1.0/24)                               │  │
│  │                                                                   │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │  │
│  │  │ orders  │  │  users  │  │payments │  │ gateway │  ... (N)   │  │
│  │  │  .NET 10│  │  .NET 10│  │ .NET 10 │  │  .NET 10│            │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └─────────┘            │  │
│  └───────┼──────────────┼──────────────┼────────────────────────────┘  │
│          │              │              │                                 │
│  ┌───────▼──────────────▼──────────────▼────────────────────────────┐  │
│  │  Subnet: SQL (10.x.2.0/24)                                       │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐ │  │
│  │  │  Azure SQL Server (shared, no public access)               │ │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌───────────┐                │ │  │
│  │  │  │orders-db │  │ users-db │  │payments-db│  (per service) │ │  │
│  │  │  └──────────┘  └──────────┘  └───────────┘                │ │  │
│  │  └─────────────────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  ┌──────────────────────┐    ┌──────────────────────────────────────┐  │
│  │  Key Vault           │    │  Static Web App (React)              │  │
│  │  (VNet-restricted)   │    │  REACT_APP_API_ORDERS, _USERS, ...   │  │
│  │  N secrets (per svc) │    │  (CDN + auto-deploy from Git)        │  │
│  └──────────────────────┘    └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

## What's Included

- **3 environments** (dev / test / prod) with isolated state and VNet CIDRs
- **Microservices via `for_each`** — add a service by adding one map entry
- **Optional SQL per service** — set `sql_enabled = false` for stateless services
- **No public SQL** — VNet service endpoint + firewall rule only
- **Key Vault** — VNet-restricted, stores per-service connection strings
- **Per-service tags** — cost attribution by service name

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | ≥ 1.6.0 |
| [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | ≥ 2.50 |
| Azure Subscription | Any (MSDN, PAYG, etc.) |

### 1. Authenticate

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Create Backend Storage (one-time)

Terraform state is stored in Azure Blob Storage. Create a storage account for it:

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

### 3. Configure

Edit `environments/dev/terraform.tfvars`:
- Set your actual GitHub repo URLs in `microservices`
- Replace `REPLACE_WITH_YOUR_SPN_OBJECT_ID` with your service principal's object ID
- Set a real SQL admin password

### 4. Init & Plan

```bash
cd environments/dev

terraform init \
  -backend-config="storage_account_name=<your-storage-account>" \
  -backend-config="container_name=terraform-state" \
  -backend-config="key=dev/terraform.tfstate"

terraform plan -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Your-Pass-123!"
```

### 5. Apply

```bash
terraform apply -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Your-Pass-123!"
```

### 6. Verify

```bash
terraform output
# api_domains   = { orders = "orders-dotnetapi-dev.azurewebsites.net", ... }
# frontend_url  = "fe-dotnetapi-dev.azurestaticapps.net"
# key_vault_uri = "https://kv-dotnetapi-dev-xxxx.vault.azure.net/"
```

### 7. Destroy (when done)

```bash
terraform destroy -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Your-Pass-123!"
```

## Adding a New Service

Edit `environments/<env>/terraform.tfvars` and add an entry to the `microservices` map:

```hcl
microservices = {
  # ... existing services ...

  inventory = {  # ← new service
    plan_sku          = "B1"
    instance_count    = 1
    dotnet_version    = "v10.0"
    repo_url          = "https://github.com/your-org/inventory-service.git"
    repo_branch       = "main"
    sql_enabled       = true
    sql_sku_name      = "GP_Gen5_2"
    sql_max_size_gb   = 25
    sql_database_name = "inventory-db"
  }
}
```

Run `terraform plan` — you'll see the new App Service, Database, and Key Vault secret. No changes to `main.tf` or modules needed.

For a service **without** a database (e.g. API gateway, notification service):

```hcl
gateway = {
  plan_sku          = "B1"
  instance_count    = 1
  dotnet_version    = "v10.0"
  repo_url          = "https://github.com/your-org/api-gateway.git"
  repo_branch       = "main"
  sql_enabled       = false  # ← no database
  sql_sku_name      = ""
  sql_max_size_gb   = 0
  sql_database_name = ""
}
```

## Project Structure

```
├── main.tf                    # Root module — wires everything together
├── variables.tf               # Input variables (the microservices map lives here)
├── outputs.tf                 # Outputs (maps per service)
├── providers.tf               # AzureRM provider + features block
├── versions.tf                # Terraform + provider version constraints
├── .gitignore
├── modules/
│   ├── networking/            # VNet, subnets, NSG
│   ├── app-service/           # App Service Plan + Linux Web App
│   ├── sql-database/          # SQL Server + Database + Firewall rule
│   ├── key-vault/             # Key Vault + per-service secrets
│   └── static-web-app/        # Static Web App (React + CDN)
└── environments/
    ├── dev/
    │   ├── backend.tf         # Remote state: dev/terraform.tfstate
    │   └── terraform.tfvars   # Dev values (B1, GP_Gen5_2, 10.0.x)
    ├── test/
    │   ├── backend.tf         # Remote state: test/terraform.tfstate
    │   └── terraform.tfvars   # Test values (S1, GP_Gen5_4, 10.1.x)
    └── prod/
        ├── backend.tf         # Remote state: prod/terraform.tfstate
        └── terraform.tfvars   # Prod values (P1v3, GP_Gen5_8, 10.2.x)
```

## How It Works

```
terraform.tfvars (per environment)
    │
    │  microservices = { orders, users, payments, gateway, ... }
    │
    ▼
main.tf
    │
    ├── module "networking"   ← 1× shared (VNet + subnets + NSG)
    ├── module "sql"          ← for_each: only services with sql_enabled = true
    ├── module "key_vault"    ← 1× shared (N secrets for services with SQL)
    ├── module "api"          ← for_each: ALL microservices
    └── module "frontend"     ← 1× shared (gets all API URLs)
```

The frontend receives `REACT_APP_API_<SERVICE_NAME>` for every service, so it can call any of them.

## CI/CD

This repo does **not** include a pipeline. You wire up your own (GitHub Actions, Azure DevOps, GitLab CI, etc.).

A typical flow:

```
MR (changes to *.tf)
  → terraform fmt -check
  → terraform validate
  → terraform plan (per environment)
  → upload plan artifact for review
  (NO APPLY on MR)

Push to main
  → terraform plan
  → terraform apply (prod requires manual approval)
```

Key things to handle in your pipeline:
- **Auth** — OIDC (preferred) or SPN
- **Secrets** — `frontend_repo_token`, `sql_server_admin_password` (never in tfvars)
- **State** — pass `-backend-config` with your storage account
- **Concurrency** — one plan/apply per environment at a time

## Environment Comparison

| | Dev | Test | Prod |
|---|---|---|---|
| App Service | B1 × 1 | S1 × 1 | P1v3 × 2 |
| SQL Database | GP_Gen5_2, 25 GB | GP_Gen5_4, 25 GB | GP_Gen5_8, 100 GB |
| Key Vault | Standard | Standard | Premium + purge protection |
| VNet CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| State key | `dev/terraform.tfstate` | `test/terraform.tfstate` | `prod/terraform.tfstate` |

## Security Notes

- SQL has **no public access** — only reachable via VNet service endpoint
- Key Vault is **VNet-restricted** (deny all, allow App Service subnet)
- App Service uses **VNet Integration** (private IP, not public)
- TLS **1.2 minimum** on all resources
- Secrets use `sensitive = true` — never printed in plan/apply output
- CI/CD uses **OIDC** — no long-lived credentials stored
- Prod apply requires **manual approval** (GitHub Environments)
- Key Vault **purge protection** enabled in prod only

## Development

```bash
# Check formatting
terraform fmt -check -recursive

# Validate syntax
terraform validate

# Plan (dev environment)
cd environments/dev
terraform plan -var-file=terraform.tfvars \
  -var "frontend_repo_token=ghp_xxx" \
  -var "sql_server_admin_password=Dev-Pass-123!"
```

## Using This as a Template

1. Clone or use as GitHub template
2. Rename `project_name` in each `terraform.tfvars`
3. Replace repo URLs with your actual service repos
4. Set your Azure subscription, storage account, and SPN
5. `terraform init` → `terraform plan` → `terraform apply`
6. Build your own CI/CD on top

## License

[MIT](LICENSE)
