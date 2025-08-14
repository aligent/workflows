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

### BigCommerce Theme Deployment

A comprehensive BigCommerce Stencil theme deployment workflow supporting theme bundling, environment promotion, asset optimization, backup/restore capabilities, and multi-environment deployment with comprehensive validation.

#### **Features**
- **Stencil CLI integration**: Complete theme bundling, validation, and deployment pipeline
- **Multi-environment support**: Staging and production deployment workflows
- **Theme validation**: Bundle size checks, file permissions, and configuration validation
- **Asset optimization**: CSS/JS compression, image optimization, and bundle optimization
- **Backup & recovery**: Automatic current theme backup with rollback capabilities
- **Version management**: Theme versioning and deployment tracking
- **Environment templating**: Configuration management across environments
- **Security validation**: Theme structure validation and dependency auditing
- **Channel management**: Support for multi-channel theme deployment
- **Debug support**: Verbose logging and comprehensive error reporting

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| store-hash | ✅ | string | | BigCommerce store hash (10 character alphanumeric) |
| environment | ❌ | string | staging | Target environment (staging/production) |
| theme-name | ✅ | string | | Theme name for identification |
| **Deployment Control** |
| activate-theme | ❌ | boolean | true | Activate theme after successful deployment |
| bundle-optimization | ❌ | boolean | true | Enable theme asset optimization and compression |
| backup-current | ❌ | boolean | true | Backup current theme before deployment |
| **Technical Configuration** |
| node-version | ❌ | string | 18 | Node.js version for Stencil CLI environment |
| stencil-version | ❌ | string | | Pin specific Stencil CLI version (optional) |
| theme-config | ❌ | string | | Theme configuration as JSON object (optional) |
| **Theme Management** |
| variation-name | ❌ | string | | Specific theme variation to activate (optional) |
| channel-ids | ❌ | string | | Channel IDs for theme application (comma-separated) |
| apply-to-all-channels | ❌ | boolean | false | Apply theme to all store channels |
| delete-oldest | ❌ | boolean | false | Delete oldest theme to make room for new deployment |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| bigcommerce-access-token | ✅ | BigCommerce API access token with theme modify scope |
| bigcommerce-client-id | ✅ | BigCommerce API client ID |
| bigcommerce-client-secret | ✅ | BigCommerce API client secret |

#### **Outputs**
| Name | Description |
|------|-------------|
| theme-uuid | Deployed theme UUID from BigCommerce |
| theme-version | Deployed theme version identifier |
| deployment-url | BigCommerce store URL for theme verification |
| backup-created | Whether current theme backup was created |

#### **Example Usage**

**Basic Staging Deployment:**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "abc123def4"
      environment: staging
      theme-name: "my-storefront-theme"
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Production Deployment with Custom Configuration:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "xyz789abc1"
      environment: production
      theme-name: "my-production-theme"
      activate-theme: true
      bundle-optimization: true
      backup-current: true
      variation-name: "Desktop"
      stencil-version: "6.15.0"
      node-version: "18"
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Multi-Channel Deployment:**
```yaml
jobs:
  deploy-multi-channel:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "def456ghi7"
      environment: staging
      theme-name: "multi-channel-theme"
      apply-to-all-channels: true
      delete-oldest: true
      theme-config: '{"logo": {"url": "https://cdn.example.com/logo.png"}, "colors": {"primary": "#ff6b35"}}'
      debug: true
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Specific Channel Deployment:**
```yaml
jobs:
  deploy-specific-channels:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "ghi789jkl0"
      environment: production
      theme-name: "channel-specific-theme"
      channel-ids: "1,2,5"
      variation-name: "Mobile"
      bundle-optimization: false
      backup-current: false
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```
