# Shopify Theme Preview Cleanup

A reusable workflow for deleting preview themes created by the [Shopify Theme PR Checks](shopify-theme-pr.md) workflow when a pull request is closed or merged.

#### **Features**
- **Automatic cleanup**: Removes the unpublished preview theme associated with a PR
- **Safe deletion**: Silently succeeds if the theme has already been removed

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| shopify-store | :heavy_check_mark: | string | | Shopify store URL (e.g. `example.myshopify.com`) |
| pr-number | :heavy_check_mark: | string | | The pull request number from the caller. Pass `github.event.pull_request.number` |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| SHOPIFY_CLI_THEME_TOKEN | :heavy_check_mark: | Theme Access app password |

#### **Example Usage**

**Cleanup on PR close:**
```yaml
on:
  pull_request:
    types: [closed]

jobs:
  cleanup-preview:
    uses: aligent/workflows/.github/workflows/shopify-theme-preview-cleanup.yml@main
    with:
      shopify-store: example.myshopify.com
      pr-number: ${{ github.event.pull_request.number }}
    secrets:
      SHOPIFY_CLI_THEME_TOKEN: ${{ secrets.SHOPIFY_CLI_THEME_TOKEN }}
```

**Combined PR and cleanup workflows:**
```yaml
# .github/workflows/shopify-theme.yml
name: Shopify Theme

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

jobs:
  pr-checks:
    if: github.event.action != 'closed'
    uses: aligent/workflows/.github/workflows/shopify-theme-pr.yml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
      deploy-preview: true
      shopify-store: example.myshopify.com
    secrets:
      SHOPIFY_CLI_THEME_TOKEN: ${{ secrets.SHOPIFY_CLI_THEME_TOKEN }}

  cleanup-preview:
    if: github.event.action == 'closed'
    uses: aligent/workflows/.github/workflows/shopify-theme-preview-cleanup.yml@main
    with:
      shopify-store: example.myshopify.com
      pr-number: ${{ github.event.pull_request.number }}
    secrets:
      SHOPIFY_CLI_THEME_TOKEN: ${{ secrets.SHOPIFY_CLI_THEME_TOKEN }}
```
