# Shopify Theme PR Checks

A reusable workflow for running quality checks on Shopify theme pull requests, with optional preview theme deployment.

#### **Features**
- **Theme Check linting**: Runs Shopify Theme Check with configurable fail levels and GitHub problem matchers for inline annotations
- **Preview deployments**: Optionally deploys an unpublished preview theme per PR, with a comment linking to the preview URL
- **Idempotent PR comments**: Preview URL comments are updated in place rather than duplicated on subsequent pushes

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| working-directory | :x: | string | `.` | Working directory for the theme |
| fail-level | :x: | string | `error` | Theme Check fail level (`error`, `warning`, `suggestion`, `style`) |
| shopify-store | :x: | string | | Shopify store URL (e.g. `example.myshopify.com`). Required when `deploy-preview` is enabled |
| deploy-preview | :x: | boolean | `false` | Deploy an unpublished preview theme per PR |
| pr-number | :heavy_check_mark: | string | | The pull request number from the caller. Pass `github.event.pull_request.number` |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| SHOPIFY_CLI_THEME_TOKEN | :x: | Theme Access app password for preview deploys. Required when `deploy-preview` is enabled |

#### **Jobs**
| Job | Description |
|-----|-------------|
| `theme-check` | Installs Shopify CLI, runs Theme Check, and surfaces offences as GitHub annotations via problem matchers |
| `preview` | Pushes the theme as an unpublished preview and comments the preview URL on the PR. Only runs when `deploy-preview` is `true` and `theme-check` passes |

#### **Example Usage**

**Basic theme linting only:**
```yaml
on:
  pull_request:

jobs:
  theme-checks:
    uses: aligent/workflows/.github/workflows/shopify-theme-pr.yml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
```

**With preview deployment:**
```yaml
on:
  pull_request:

jobs:
  theme-checks:
    uses: aligent/workflows/.github/workflows/shopify-theme-pr.yml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
      deploy-preview: true
      shopify-store: example.myshopify.com
    secrets:
      SHOPIFY_CLI_THEME_TOKEN: ${{ secrets.SHOPIFY_CLI_THEME_TOKEN }}
```

**Monorepo with stricter fail level:**
```yaml
on:
  pull_request:
    paths:
      - 'themes/storefront/**'

jobs:
  theme-checks:
    uses: aligent/workflows/.github/workflows/shopify-theme-pr.yml@main
    with:
      working-directory: themes/storefront
      fail-level: warning
      pr-number: ${{ github.event.pull_request.number }}
```
