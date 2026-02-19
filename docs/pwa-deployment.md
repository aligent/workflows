# PWA Deployment

A comprehensive Progressive Web Application deployment workflow supporting S3 static hosting with CloudFront CDN, multi-environment deployments, branch-based previews, and multi-brand configurations.

#### **Features**
- **Multi-environment support**: staging, production, and preview environments
- **Branch-based previews**: Automatic preview deployments for pull requests
- **Dual cache strategies**: Immutable caching for static assets, revalidation for HTML
- **CloudFront integration**: Automatic cache invalidation with configurable paths
- **Multi-brand deployment**: Parallel deployment support for multiple brands
- **Node.js 16-22 support**: Compatible with Yarn and npm package managers
- **Manual production gates**: Environment-based deployment protection
- **Comprehensive caching**: Build artifact optimisation and cleanup

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **AWS Configuration** |
| aws-region | :x: | string | ap-southeast-2 | AWS region for deployment |
| s3-bucket | :white_check_mark: | string | | S3 bucket name for deployment |
| cloudfront-distribution-id | :white_check_mark: | string | | CloudFront distribution ID for cache invalidation |
| **Environment Configuration** |
| environment | :x: | string | staging | Deployment environment (GitHub environment name for protection rules) |
| **Build Configuration** |
| package-manager | :x: | string | yarn | Node package manager (yarn/npm) |
| is-yarn-classic | :x: | boolean | false | Use Yarn Classic (pre-Berry) instead of modern Yarn |
| build-command | :x: | string | build | Build command to execute |
| build-directory | :x: | string | dist | Directory containing built assets to deploy |
| **Cache Strategy Configuration** |
| cache-strategy | :x: | string | immutable | Cache strategy for assets (immutable/no-cache) |
| **Preview Environment Configuration** |
| preview-mode | :x: | boolean | false | Enable preview mode for PR-based deployments |
| preview-base-url | :x: | string | | Base URL for preview deployments |
| **Multi-brand Configuration** |
| brand-config | :x: | string | | JSON configuration for multi-brand deployments |
| **Advanced Configuration** |
| cloudfront-invalidation-paths | :x: | string | ["/*"] | CloudFront invalidation paths (JSON array) |
| extra-sync-args | :x: | string | | Additional AWS S3 sync arguments |
| **Debug and Control** |
| debug | :x: | boolean | false | Enable verbose logging and debug output |
| skip-build | :x: | boolean | false | Skip the build step (use pre-built assets) |
| skip-tests | :x: | boolean | false | Skip test execution |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-access-key-id | :white_check_mark: | AWS access key ID |
| aws-secret-access-key | :white_check_mark: | AWS secret access key |

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
```
