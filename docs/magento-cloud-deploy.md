# Magento Cloud Deployment

A simple Magento Cloud deployment workflow that pushes code to your Magento Cloud git repository with optional NewRelic monitoring and CST reporting.

#### **Features**
- **Multi-environment support**: integration, staging, and production deployments
- **Simple git push**: No composer install, patching, or building - just pushes code
- **NewRelic integration**: Optional deployment markers for tracking deployment lifecycle (start/complete)
- **CST system integration**: Optional composer.lock reporting to Confidentiality and Security Team
- **Environment protection**: Uses GitHub environment protection rules for deployment gates
- **Full git history support**: Required for Magento Cloud deployment requirements
- **Parallel post-deployment**: NewRelic completion and CST reporting run in parallel for efficiency

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Magento Cloud Configuration** |
| magento-cloud-project-id | ✅ | string | | Magento Cloud project ID (required) |
| environment | ❌ | string | integration | Target environment (integration/staging/production) |
| **Monitoring and Reporting** |
| newrelic-app-id | ❌ | string | | NewRelic application ID for deployment markers (optional) |
| **CST Reporting Configuration** |
| cst-endpoint | ❌ | string | | CST endpoint base URL (optional, overrides workspace variable) |
| cst-project-key | ❌ | string | | CST project key (optional, overrides workspace variable) |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| magento-cloud-cli-token | ✅ | Magento Cloud CLI token for authentication |
| newrelic-api-key | ❌ | NewRelic API key for deployment markers (optional) |
| cst-reporting-token | ❌ | CST reporting token (workspace-level secret, optional) |

#### **Workspace Variables (Optional)**
| Name | Description |
|------|-------------|
| CST_ENDPOINT | CST endpoint base URL (e.g., `https://package.report.aligent.consulting`) |
| CST_PROJECT_KEY | CST project identifier for your organization |

#### **Outputs**
| Name | Description |
|------|-------------|
| deployment-url | URL of the deployed Magento application |
| deployment-id | Magento Cloud deployment ID |

#### **Example Usage**

**Basic Integration Deployment:**
```yaml
jobs:
  deploy-integration:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: integration
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Production Deployment with NewRelic Monitoring:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: production
      newrelic-app-id: "123456789"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
      newrelic-api-key: ${{ secrets.NEWRELIC_API_KEY }}
```

**Staging Deployment with CST Reporting:**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: staging
      debug: true
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Deployment with CST Reporting Override:**
```yaml
jobs:
  deploy-with-cst:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: staging
      cst-endpoint: "https://package.report.aligent.consulting"
      cst-project-key: "your-project-key"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
      cst-reporting-token: ${{ secrets.CST_REPORTING_TOKEN }}
```