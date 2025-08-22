# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

### Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use       |
| is-yarn-classic   | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that the project uses a pre-Berry version of Yarn, which changes what flags we can pass to the command       |
| skip-cache      | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that we should use the `--force` flag to tell Yarn to ignore cache and fetch dependencies from the package repository       |
| build-command   | ❌      | string   | build            | Command to override the build command |
| test-command    | ❌      | string   | test             | Command to override the test command |
| lint-command    | ❌      | string   | lint             | Command to override the lint command |
| format-command  | ❌      | string   | format           | Command to override the format command |
| skip-build      | ❌      | boolean  | false            | If the build step should be skipped |
| skip-test       | ❌      | boolean  | false            | If the test step should be skipped |
| skip-lint       | ❌      | boolean  | false            | If the lint step should be skipped |
| skip-format     | ❌      | boolean  | false            | If the format step should be skipped |
| debug           | ❌      | boolean  | false            | If debug flags should be set |

#### Example Usage

```yaml
jobs:
  test-s3-deploy:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      skip-format: false
```

### S3 Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                               |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-region           | ❌       | string  | ap-southeast-2  | AWS region                                 |
| s3-bucket            | ✅       | string  |                 | Name of the S3 bucket                      |
| s3-path              | ❌       | string  |                 | Path in the S3 bucket                      |
| local-path           | ✅       | string  |                 | Path to deploy                             |
| delete-flag          | ❌       | boolean | true            | Enable --delete flag                       |
| cache-control        | ❌       | string  |                 | Cache control headers                      |
| extra-args           | ❌       | string  |                 | Additional AWS CLI args                    |

#### **Secrets**
| Name                  | Required | Description                               |
|--------------------- |----------|--------------------------------------------|
| aws-access-key-id    | ✅       | AWS Access Key ID                          |
| aws-secret-access-key| ✅       | AWS Secret Access Key                      |

#### Example Usage

```yaml
jobs:
  deploy-to-s3:
    uses: aligent/workflows/.github/workflows/s3-deploy.yml@main
    with:
      s3-bucket: my-bucket
      local-path: ./dist
      s3-path: /public
      cache-control: "max-age=3600"
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Magento Cloud Deployment

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
| cst-reporting-key | ❌ | string | | CST reporting key (optional, overrides workspace secret) |
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
      cst-reporting-key: "custom-key-123"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

#### **CST Reporting Configuration**

The CST (Confidentiality and Security Team) reporting feature can be configured in two ways:

1. **Workspace-level configuration (recommended):**
   - Set `CST_ENDPOINT` as a repository/organization variable (base URL, e.g., `https://package.report.aligent.consulting`)
   - Set `CST_PROJECT_KEY` as a repository/organization variable (your project identifier)
   - Set `cst-reporting-token` as a repository/organization secret
   - The workflow will automatically use these when available

2. **Input overrides (optional):**
   - Use `cst-endpoint` input to override the workspace variable (base URL)
   - Use `cst-project-key` input to override the workspace variable (project identifier)
   - Use `cst-reporting-key` input to override the workspace secret
   - Useful for testing or special deployments

The workflow constructs the full CST URL as: `{endpoint}/{project-key}/adobe-commerce`

CST reporting only runs when endpoint, project key, and auth key are all configured. If any are missing, the step is skipped with an informational message.
### Nx Serverless Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                               |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key                             |
| aws-secret-access-key| ✅       | string  |                 | AWS Secret Access Key                      |
| cfn-role             | ✅       | string  |                 | AWS CFN Role to assume                     |
| aws-profile          | ✅       | string  |                 | AWS Profile                                |
| aws-region           | ❌       | string  | ap-southeast-2  | AWS Region to deploy to                    |
| stage                | ✅       | string  |                 | Stage to deploy to                         |
| environment          | ✅       | string  |                 | The GitHub environment to run in           |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

#### Example Usage

```yaml
jobs:
  deploy-serverless:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      aws-profile: my-profile
      stage: dev
      environment: development
      debug: true
    secrets:
      aws-access-key-id: '123'
      aws-secret-access-key: '456'
```
