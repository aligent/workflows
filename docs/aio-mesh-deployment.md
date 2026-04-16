# AIO Mesh Deployment

Creates or updates an Adobe I/O API Mesh. Automatically detects whether the mesh already exists and calls `aio api-mesh:create` or `aio api-mesh:update` accordingly. Polls until provisioning completes. Supports both standalone mesh repos and meshes within NX monorepos.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| `environment` | ✅ | string | | GitHub environment to run in |
| `aio-cli-version` | ❌ | string | `11.x.x` | Adobe I/O CLI version to install |
| `mesh-config` | ❌ | string | `mesh.json` | Path to the mesh config file, relative to `mesh-directory` |
| `mesh-directory` | ❌ | string | `.` | Working directory for the mesh, relative to the repo root. Use for NX monorepo subdirectories. |
| `package-manager` | ❌ | string | `yarn` | Node package manager to use (`npm` or `yarn`) |
| `build-command` | ❌ | string | | Command to run before deploying (e.g. `yarn build:resolvers`). Required when the mesh uses custom resolvers that must be compiled first. |
| `provisioning-timeout` | ❌ | number | `300` | Seconds to wait for provisioning before failing |
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

**AIO Project** — required:

| Name | Type | Description |
|------|------|-------------|
| `AIO_PROJECT_ID` | Variable | Adobe I/O project ID |
| `AIO_PROJECT_ORG_ID` | Variable | Adobe I/O project org ID |
| `AIO_PROJECT_WORKSPACE_ID` | Variable | Adobe I/O workspace ID |

**Mesh configuration** — optional:

| Name | Type | Description |
|------|------|-------------|
| `AIO_MESH_ENV_VARS` | Variable | Environment variables to inject into the mesh via `.env` (passed as `--env=.env`) |
| `AIO_MESH_SECRETS` | Secret | Secrets to inject into the mesh via `secrets.yaml` (passed as `--secrets=secrets.yaml`) |

Both fields accept multiline `KEY=VALUE` pairs — one per line. If neither is set, the `--env` and `--secrets` flags are omitted from the mesh command.

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

Example `AIO_MESH_ENV_VARS` value:
```
BACKEND_ENDPOINT=https://api.example.com
CATEGORIES_URL=https://api.example.com/categories
```

Example `AIO_MESH_SECRETS` value:
```
AUTH_HASH=abc123
INTERNAL_API_URL=https://internal.example.com/parts
```

---

#### **Example Usage**

##### Standalone mesh repo

```yaml
name: Deploy API Mesh

on:
  push:
    branches:
      - staging
      - production

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aio-mesh-deployment.yml@main
    with:
      environment: ${{ github.ref_name }}
    secrets: inherit
```

GitHub Environments `staging` and `production` each contain the required AIO secrets. Optionally set `AIO_MESH_ENV_VARS` and `AIO_MESH_SECRETS` for mesh-specific configuration.

---

##### Standalone mesh with custom resolvers

When the mesh requires a build step before deployment (e.g. TypeScript resolvers):

```yaml
name: Deploy API Mesh

on:
  push:
    branches:
      - staging
      - production

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aio-mesh-deployment.yml@main
    with:
      environment: ${{ github.ref_name }}
      build-command: yarn build:resolvers
    secrets: inherit
```

---

##### NX monorepo — mesh as a subdirectory

When a mesh lives alongside AIO apps in a monorepo:

```yaml
name: Deploy

on:
  push:
    branches:
      - main
  workflow_dispatch:
    inputs:
      app:
        description: App to deploy (use 'common-api-mesh' to deploy the mesh only)
        required: false
        type: string

jobs:
  affected:
    name: Get Affected Apps
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.affected.outputs.matrix }}
      has_affected: ${{ steps.affected.outputs.has_affected }}
      mesh_affected: ${{ steps.affected.outputs.mesh_affected }}
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
            if [ "$APP_INPUT" = "common-api-mesh" ]; then
              echo "mesh_affected=true" >> $GITHUB_OUTPUT
              echo "has_affected=false" >> $GITHUB_OUTPUT
              echo "matrix=[]" >> $GITHUB_OUTPUT
            else
              matrix=$(echo "$APP_INPUT" | jq -R -c '[.]')
              echo "has_affected=true" >> $GITHUB_OUTPUT
              echo "matrix=$matrix" >> $GITHUB_OUTPUT
              echo "mesh_affected=false" >> $GITHUB_OUTPUT
            fi
          else
            BASE="${BASE_SHA:-origin/main~1}"
            all_apps=$(npx nx show projects --affected --base="$BASE" --head=HEAD || echo "")
            if [ -z "$all_apps" ]; then
              echo "has_affected=false" >> $GITHUB_OUTPUT
              echo "matrix=[]" >> $GITHUB_OUTPUT
              echo "mesh_affected=false" >> $GITHUB_OUTPUT
            else
              if echo "$all_apps" | grep -q "^common-api-mesh$"; then
                echo "mesh_affected=true" >> $GITHUB_OUTPUT
              else
                echo "mesh_affected=false" >> $GITHUB_OUTPUT
              fi
              other_apps=$(echo "$all_apps" | grep -v "^common-api-mesh$" || true)
              if [ -z "$other_apps" ]; then
                echo "has_affected=false" >> $GITHUB_OUTPUT
                echo "matrix=[]" >> $GITHUB_OUTPUT
              else
                matrix=$(echo "$other_apps" | jq -R -s -c 'split("\n") | map(select(length > 0))')
                echo "has_affected=true" >> $GITHUB_OUTPUT
                echo "matrix=$matrix" >> $GITHUB_OUTPUT
              fi
            fi
          fi

  deploy-apps:
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

  deploy-mesh:
    name: Deploy API Mesh
    needs: affected
    if: needs.affected.outputs.mesh_affected == 'true'
    uses: aligent/workflows/.github/workflows/aio-mesh-deployment.yml@main
    with:
      environment: common-api-mesh-production
      mesh-directory: common-api-mesh
    secrets: inherit
```

The GitHub Environment for each app (e.g. `common-api-mesh-production`) contains its own AIO secrets and any mesh-specific `AIO_MESH_ENV_VARS` / `AIO_MESH_SECRETS`.
