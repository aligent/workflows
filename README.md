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

### PWA Deployment

A comprehensive Progressive Web Application deployment workflow supporting S3 static hosting with CloudFront CDN, multi-environment deployments, branch-based previews, and multi-brand configurations.

#### **Features**
- **Multi-environment support**: staging, production, and preview environments
- **Branch-based previews**: Automatic preview deployments for pull requests
- **Dual cache strategies**: Immutable caching for static assets, revalidation for HTML
- **CloudFront integration**: Automatic cache invalidation with configurable paths
- **Multi-brand deployment**: Parallel deployment support for multiple brands
- **Node.js 16-22 support**: Compatible with Yarn and npm package managers
- **Manual production gates**: Environment-based deployment protection
- **Comprehensive caching**: Build artifact optimization and cleanup

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **AWS Configuration** |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| s3-bucket | ✅ | string | | S3 bucket name for deployment |
| cloudfront-distribution-id | ✅ | string | | CloudFront distribution ID for cache invalidation |
| **Environment Configuration** |
| environment | ❌ | string | staging | Deployment environment (GitHub environment name for protection rules) |
| **Build Configuration** |
| package-manager | ❌ | string | yarn | Node package manager (yarn/npm) |
| is-yarn-classic | ❌ | boolean | false | Use Yarn Classic (pre-Berry) instead of modern Yarn |
| build-command | ❌ | string | build | Build command to execute |
| build-directory | ❌ | string | dist | Directory containing built assets to deploy |
| **Cache Strategy Configuration** |
| cache-strategy | ❌ | string | immutable | Cache strategy for assets (immutable/no-cache) |
| **Preview Environment Configuration** |
| preview-mode | ❌ | boolean | false | Enable preview mode for PR-based deployments |
| preview-base-url | ❌ | string | | Base URL for preview deployments |
| **Multi-brand Configuration** |
| brand-config | ❌ | string | | JSON configuration for multi-brand deployments |
| **Advanced Configuration** |
| cloudfront-invalidation-paths | ❌ | string | ["/*"] | CloudFront invalidation paths (JSON array) |
| extra-sync-args | ❌ | string | | Additional AWS S3 sync arguments |
| **Debug and Control** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |
| skip-build | ❌ | boolean | false | Skip the build step (use pre-built assets) |
| skip-tests | ❌ | boolean | false | Skip test execution |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-access-key-id | ✅ | AWS access key ID |
| aws-secret-access-key | ✅ | AWS secret access key |

#### **Outputs**
| Name | Description |
|------|-------------|
| deployment-url | URL of the deployed application |
| preview-url | Preview URL for PR deployments |

#### **Example Usage**

**Basic Production Deployment:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      s3-bucket: my-production-bucket
      cloudfront-distribution-id: E1234567890ABC
      environment: production
      cache-strategy: immutable
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Preview Environment for Pull Requests:**
```yaml
jobs:
  deploy-preview:
    if: github.event_name == 'pull_request'
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      s3-bucket: my-preview-bucket
      cloudfront-distribution-id: E1234567890ABC
      environment: preview
      preview-mode: true
      preview-base-url: https://preview.example.com
      cache-strategy: no-cache
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Multi-brand Deployment:**
```yaml
jobs:
  deploy-multi-brand:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      s3-bucket: my-multi-brand-bucket
      cloudfront-distribution-id: E1234567890ABC
      environment: production
      brand-config: '{"brand":["brand-a","brand-b","brand-c"]}'
      build-command: build:brands
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Custom Build Configuration:**
```yaml
jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      s3-bucket: my-custom-bucket
      cloudfront-distribution-id: E1234567890ABC
      environment: staging
      package-manager: npm
      build-command: build:staging
      build-directory: build
      cloudfront-invalidation-paths: '["/*", "/api/*"]'
      extra-sync-args: --exclude "*.map"
      debug: true
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
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
