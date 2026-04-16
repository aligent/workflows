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
- **Automatic backporting**: Optional PR creation to backport changes to staging branch

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| app-name | ✅ | string | | Gadget App name to deploy to |
| working-directory | ❌ | string | . | Working directory of Gadget App |
| environment-name | ⚠️ | string | | Gadget environment name (required when `action: push`) |
| **Deployment Control** |
| action | ✅ | string | | Deployment action: `push` (push to environment) or `deploy` (deploy to production) |
| test | ❌ | boolean | false | Enable testing on development environment |
| **Backport Configuration** |
| create-backport-pr | ❌ | boolean | false | Create a backport PR after deployment |
| backport-target-branch | ❌ | string | staging | Target branch for backport PR |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| gadget-api-token | ✅ | Gadget API authentication token |
| gadget-test-api-key | ❌ | Gadget Test API key (required when `test: true`) |

#### **Outputs**
| Name | Description |
|------|-------------|
| push-environment-status | Status of test environment push (success/failure) |

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

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
      action: push
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
      action: push
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
      action: push
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
      action: deploy
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

When `action: deploy`, the workflow uses a temporary environment strategy to safely promote code to production:

1. **Create** — A temporary Gadget environment named `deploy-<run_id>` is created (e.g. `deploy-12345678`), using the GitHub Actions run ID for uniqueness. This ensures the deployment is isolated from the main development/staging environment.
2. **Push** — The checked-out code is pushed to this temporary environment using `ggt push`.
3. **Deploy** — The temporary environment is promoted to production using `ggt deploy`.
4. **Cleanup** — The temporary environment is deleted after deployment, regardless of success or failure.

This approach avoids deploying uncommitted or unreviewed changes that may exist in the shared staging environment, ensuring only the exact code from the Git ref is promoted to production.
