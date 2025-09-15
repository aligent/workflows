# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

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
