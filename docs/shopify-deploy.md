# Shopify App Deployment

A reusable workflow for deploying Shopify apps using the Shopify CLI with support for staging and production environments.

#### **Features**
- **Multi-environment support**: Deploy to staging or production using different TOML configuration files
- **Configurable working directory**: Support for monorepo structures with custom app locations
- **Build artifact integration**: Downloads pre-built artifacts before deployment
- **Shopify CLI integration**: Uses Shopify CLI for configuration and deployment
- **Deployment validation**: Ensures at least one deployment target is selected

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| working-directory | ❌ | string | . | Working directory for the app |
| development-toml-name | ❌ | string | shopify.app.development.toml | Name of development TOML config file |
| production-toml-name | ❌ | string | shopify.app.toml | Name of production TOML config file |
| **Deployment Control** |
| deploy-staging | ❌ | boolean | false | Enable staging deployment |
| deploy-production | ❌ | boolean | false | Enable production deployment |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| shopify_cli_token | ✅ | Shopify CLI authentication token |

#### **Prerequisites**
- A `.nvmrc` file in the repository root specifying the Node.js version
- A `yarn.lock` file in the working directory
- Build artifacts uploaded with the name `build-artifacts` from a previous job
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
      deploy-staging: true
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
  build:
  deploy-production:
    uses: aligent/workflows/.github/workflows/shopify-deploy.yml@main
    with:
      working-directory: apps/shopify-app
      deploy-production: true
    secrets:
      shopify_cli_token: ${{ secrets.SHOPIFY_CLI_TOKEN }}
```

**Custom TOML Configuration:**
```yaml
jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/shopify-deploy.yml@main
    with:
      working-directory: apps/shopify-app
      development-toml-name: shopify.app.dev.toml
      production-toml-name: shopify.app.prod.toml
      deploy-staging: true
    secrets:
      shopify_cli_token: ${{ secrets.SHOPIFY_CLI_TOKEN }}
```
