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
- **Automatic backporting**: Optional PR creation to backport changes to staging branch

#### **GitHub Environment Variables and Secrets**

Environment-specific values are read directly from the GitHub Environment (set via `github-environment`), rather than being passed as workflow inputs. Configure the following on each environment:

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `S3_BUCKET` | variable | :white_check_mark: | S3 bucket name for deployment |
| `CLOUDFRONT_DISTRIBUTION_ID` | variable | :white_check_mark: | CloudFront distribution ID for cache invalidation |
| `AWS_REGION` | variable | :x: | AWS region (falls back to `aws-region` input) |
| **Static credentials** | | | |
| `AWS_ACCESS_KEY_ID` | variable | :white_check_mark: | AWS access key ID (required if not using OIDC) |
| `AWS_SECRET_ACCESS_KEY` | secret | :white_check_mark: | AWS secret access key (required if not using OIDC) |
| **OIDC** | | | |
| `AWS_ROLE_ARN` | variable | :white_check_mark: | IAM role ARN to assume via OIDC (alternative to static credentials) |

Either `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` **or** `AWS_ROLE_ARN` must be configured. The workflow detects which to use automatically.

#### **Backport Configuration (Optional)**

Enable automatic PR creation to backport changes to a staging branch after successful deployments.

| Name | Type | Description |
|------|------|-------------|
| `BACKPORT_TO_STAGING` | variable | Set to `true` to enable backporting |
| `BACKPORT_TARGET_BRANCH` | variable | Target branch for backport (defaults to `staging`) |

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Environment Configuration** |
| github-environment | :white_check_mark: | string | | GitHub Environment name for secrets/variables (e.g. Staging, Production) |
| **AWS Configuration** |
| aws-region | :x: | string | ap-southeast-2 | AWS region fallback (overridden by `AWS_REGION` environment variable if set) |
| role-session-name | :x: | string | | AWS role session name for OIDC (default: `{repo}-{short-sha}-{run-number}`) |
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

#### **Outputs**
| Name | Description |
|------|-------------|
| deployment-url | URL of the deployed application |
| preview-url | Preview URL for PR deployments |

#### **Example Usage**

**Basic Deployment (Static Credentials):**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      github-environment: Staging
    secrets: inherit
```

The `Staging` GitHub Environment must have `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` configured.

**Basic Deployment (OIDC):**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      github-environment: Production
    secrets: inherit
```

The `Production` GitHub Environment must have `S3_BUCKET`, `CLOUDFRONT_DISTRIBUTION_ID`, and `AWS_ROLE_ARN` configured.

**Preview Environment for Pull Requests:**
```yaml
jobs:
  deploy-preview:
    if: github.event_name == 'pull_request'
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      github-environment: Preview
      preview-mode: true
      preview-base-url: https://preview.example.com
      cache-strategy: no-cache
    secrets: inherit
```

**Multi-brand Deployment:**
```yaml
jobs:
  deploy-multi-brand:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      github-environment: Production
      brand-config: '{"brand":["brand-a","brand-b","brand-c"]}'
      build-command: build:brands
    secrets: inherit
```

**Custom Build Configuration:**
```yaml
jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/pwa-deployment.yml@main
    with:
      github-environment: Staging
      package-manager: npm
      build-command: build:staging
      build-directory: build
      cloudfront-invalidation-paths: '["/*", "/api/*"]'
      extra-sync-args: --exclude "*.map"
      debug: true
    secrets: inherit
```
