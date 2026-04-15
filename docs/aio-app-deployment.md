# AIO App Deployment

Deploys an Adobe I/O App Builder application using `aio app deploy`. Supports both standalone apps and apps within NX monorepos.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| `environment` | ✅ | string | | GitHub environment to run in |
| `aio-cli-version` | ❌ | string | `11.x.x` | Adobe I/O CLI version to install |
| `app-directory` | ❌ | string | `.` | Working directory for the app, relative to the repo root. Use for NX monorepo subdirectory apps. |
| `package-manager` | ❌ | string | `yarn` | Node package manager to use (`npm` or `yarn`) |
| `debug` | ❌ | boolean | `false` | Enable verbose logging |
| `create-backport-pr` | ❌ | boolean | `false` | Create a backport PR after deployment |
| `backport-target-branch` | ❌ | string | `staging` | Target branch for backport PR |

#### **Variables and Secrets**

Configure these in the GitHub Environment (or at the repository level if not using environments).

**AIO Authentication** — required:

| Name | Type | Description |
|------|------|-------------|
| `AIO_CLIENT_ID` | Secret | Adobe I/O OAuth client ID |
| `AIO_CLIENT_SECRET` | Secret | Adobe I/O OAuth client secret |
| `AIO_TECHNICAL_ACCOUNT_ID` | Secret | Technical account ID |
| `AIO_TECHNICAL_ACCOUNT_EMAIL` | Secret | Technical account email |
| `AIO_IMS_ORG_ID` | Secret | IMS organisation ID |
| `AIO_SCOPES` | Secret | OAuth scopes (space or comma separated) |

**AIO Runtime / Project** — required:

| Name | Type | Description |
|------|------|-------------|
| `AIO_RUNTIME_NAMESPACE` | Secret | Adobe I/O Runtime namespace |
| `AIO_RUNTIME_AUTH` | Secret | Adobe I/O Runtime auth token |
| `AIO_PROJECT_ID` | Variable | Adobe I/O project ID |
| `AIO_PROJECT_NAME` | Variable | Adobe I/O project name |
| `AIO_PROJECT_ORG_ID` | Variable | Adobe I/O project org ID |
| `AIO_PROJECT_WORKSPACE_ID` | Variable | Adobe I/O workspace ID |
| `AIO_PROJECT_WORKSPACE_NAME` | Variable | Adobe I/O workspace name |

**App-specific extras** — optional:

| Name | Type | Description |
|------|------|-------------|
| `AIO_DEPLOY_EXTRA_VARS` | Variable | Additional non-secret environment variables to inject into the deploy step |
| `AIO_DEPLOY_EXTRA_SECRETS` | Secret | Additional secret environment variables to inject into the deploy step |

Both extra fields accept multiline `KEY=VALUE` pairs — one per line. Use these for app-specific runtime configuration that varies per project, such as third-party API credentials, AWS credentials, or feature flags.

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

Example `AIO_DEPLOY_EXTRA_VARS` value:
```
AWS_REGION=ap-southeast-2
AWS_SNS_ARN=arn:aws:sns:ap-southeast-2:123456789:my-topic
STAGE=production
```

Example `AIO_DEPLOY_EXTRA_SECRETS` value:
```
EXTERNAL_API_BASE_URL=https://api.example.com
EXTERNAL_API_KEY=abc123
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
```

---

#### **Example Usage**

##### Standalone app

```yaml
name: Deploy

on:
  push:
    branches:
      - staging
      - production

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aio-app-deployment.yml@main
    with:
      environment: ${{ github.ref_name }}
    secrets: inherit
```

GitHub Environments `staging` and `production` each contain the required AIO secrets plus any app-specific extras in `AIO_DEPLOY_EXTRA_VARS` / `AIO_DEPLOY_EXTRA_SECRETS`.

---

##### NX monorepo — affected apps only

For NX monorepos, affected-app detection is the caller's responsibility. The workflow is called once per app using a matrix strategy.

```yaml
name: Deploy

on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      app:
        description: App to deploy (leave empty to deploy all affected apps)
        required: false
        type: string

jobs:
  affected:
    name: Get Affected Apps
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.affected.outputs.matrix }}
      has_affected: ${{ steps.affected.outputs.has_affected }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          fetch-depth: 0

      - uses: actions/setup-node@53b83947a5a98c8d113130e565377fae1a50d02f # v6.3.0
        with:
          node-version-file: .nvmrc

      - name: Install nx
        run: npm install --no-save --ignore-scripts nx

      - name: Get affected apps
        id: affected
        env:
          APP_INPUT: ${{ inputs.app }}
          BASE_SHA: ${{ github.event.before }}
        run: |
          if [ -n "$APP_INPUT" ]; then
            matrix=$(echo "$APP_INPUT" | jq -R -c '[.]')
            echo "has_affected=true" >> $GITHUB_OUTPUT
            echo "matrix=$matrix" >> $GITHUB_OUTPUT
          else
            BASE="${BASE_SHA:-origin/main~1}"
            apps=$(npx nx show projects --affected --base="$BASE" --head=HEAD || echo "")
            if [ -z "$apps" ]; then
              echo "has_affected=false" >> $GITHUB_OUTPUT
              echo "matrix=[]" >> $GITHUB_OUTPUT
            else
              matrix=$(echo "$apps" | jq -R -s -c 'split("\n") | map(select(length > 0))')
              echo "has_affected=true" >> $GITHUB_OUTPUT
              echo "matrix=$matrix" >> $GITHUB_OUTPUT
            fi
          fi

  deploy:
    name: Deploy ${{ matrix.app }}
    needs: affected
    if: needs.affected.outputs.has_affected == 'true'
    strategy:
      matrix:
        app: ${{ fromJson(needs.affected.outputs.matrix) }}
    uses: aligent/workflows/.github/workflows/aio-app-deployment.yml@main
    with:
      environment: ${{ matrix.app }}-production
      app-directory: ${{ matrix.app }}
    secrets: inherit
```

Each app gets its own GitHub Environment (e.g. `my-app-production`) containing that app's AIO secrets and any project-specific extras.

---

##### NX monorepo — all apps (no affected detection)

```yaml
name: Deploy All

on:
  workflow_dispatch:

jobs:
  deploy-app-one:
    uses: aligent/workflows/.github/workflows/aio-app-deployment.yml@main
    with:
      environment: app-one-production
      app-directory: app-one
    secrets: inherit

  deploy-app-two:
    uses: aligent/workflows/.github/workflows/aio-app-deployment.yml@main
    with:
      environment: app-two-production
      app-directory: app-two
    secrets: inherit
```
