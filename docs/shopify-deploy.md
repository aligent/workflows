# Shopify App Deployment

A reusable workflow for deploying Shopify apps using the Shopify CLI.

#### **Features**
- **Configurable working directory**: Support for monorepo structures with custom app locations
- **Shopify CLI integration**: Uses Shopify CLI for configuration and deployment
- **Deployment validation**: Ensures at least one deployment target is selected
- **Automatic backporting**: Optional PR creation to backport changes to staging branch

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| working-directory | ❌ | string | . | Working directory for the app |
| shopify-toml-name | ✅ | string | | Name of Shopify TOML configuration file |
| **Backport Configuration** |
| create-backport-pr | ❌ | boolean | false | Create a backport PR after deployment |
| backport-target-branch | ❌ | string | staging | Target branch for backport PR |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| shopify_cli_token | ✅ | Shopify CLI authentication token |

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

#### **Prerequisites**
- A `.nvmrc` file in the repository root specifying the Node.js version
- A `yarn.lock` file in the working directory
- Shopify app TOML configuration files for each environment

#### **Example Usage**

**Deploy to Staging:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/shopify-deploy.yml@main
    with:
      working-directory: apps/shopify-app
      shopify-toml-name: shopify.app.staging.toml
    secrets:
      shopify_cli_token: ${{ secrets.SHOPIFY_CLI_TOKEN }}
```

**Deploy to Production:**
```yaml
on:
  release:
    types: [published]

...

jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/shopify-deploy.yml@main
    with:
      working-directory: apps/shopify-app
      shopify-toml-name: shopify.app.toml
    secrets:
      shopify_cli_token: ${{ secrets.SHOPIFY_CLI_TOKEN }}
```
