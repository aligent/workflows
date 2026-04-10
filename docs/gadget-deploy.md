# Gadget App Deployment

A comprehensive Gadget app deployment workflow supporting push, test, and production deployment stages with multi-environment management.

#### **Features**
- **Custom-environment support**: Support for custom development environment name
- **Conditional automated testing**: Automatic test execution controlled by boolean flag
- **Conditional deployment**: Production deployment controlled by boolean flag
- **Temporary environment deployment**: Production deploys create a temporary Gadget environment, push code to it, promote to production, and clean up automatically
- **Force push capabilities**: Ensures code synchronization with `--force` flag
- **Gadget CLI integration**: Uses `ggt` CLI tool for all operations
- **Test validation**: Runs full test suite before production deployment

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| app-name | ✅ | string | | Gadget App name to deploy to |
| working-directory | ❌ | string | . | Working directory of Gadget App |
| environment-name | ❌ | string | staging | Main _development_ environment name |
| **Deployment Control** |
| push-staging | ❌ | boolean | false | Enable production deployment |
| test | ❌ | boolean | false | Enable testing on development environment |
| deploy-production | ❌ | boolean | false | Enable production deployment |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| gadget-api-token | ✅ | Gadget API authentication token |
| gadget-test-api-key | ❌ | Gadget Test API key (required when `test: true`) |

#### **Outputs**
| Name | Description |
|------|-------------|
| push-environment-status | Status of test environment push (success/failure) |

#### **Example Usage**

**Push to Staging Only:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  push-staging:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      working-directory: apps/gadget-app
      environment-name: staging
      push-staging: true
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

**Push to custom Environment Name:**
```yaml
on:
  push:
    branches:
      - staging

...


jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      environment-name: development
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

**Push with Testing:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  push-and-test:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      working-directory: apps/gadget-app
      environment-name: staging
      push-staging: true
      test: true
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
      gadget-test-api-key: ${{ secrets.GADGET_TEST_API_KEY }}
```

**Production deployment from Release:**
```yaml
on:
  release:
    types: [published]

...

jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      working-directory: apps/gadget-app
      environment-name: ${{ github.event.release.tag_name }}
      deploy-production: true
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

When `deploy-production: true`, the workflow uses a temporary environment strategy to safely promote code to production:

1. **Sanitize** — The `environment-name` is sanitized to meet Gadget's naming requirements (lowercase `a-z`, `0-9`, and dashes only). For example, `v1.2.0` becomes `v1-2-0`.
2. **Create** — A temporary Gadget environment is created using the sanitized name. This ensures the deployment is isolated from the main development/staging environment.
3. **Push** — The checked-out code is pushed to this temporary environment using `ggt push`.
4. **Deploy** — The temporary environment is promoted to production using `ggt deploy`.
5. **Cleanup** — The temporary environment is deleted after deployment, regardless of success or failure.

This approach avoids deploying uncommitted or unreviewed changes that may exist in the shared staging environment, ensuring only the exact code from the Git ref is promoted to production.
