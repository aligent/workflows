# AIO Secure Actions

Applies web-secure authentication to a specified set of Adobe I/O Runtime actions using `aio runtime action update --web=true --web-secure=<hash>`. Action names are resolved to their full `namespace/name` path via `aio runtime action list` before updating.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| `environment` | ✅ | string | | GitHub environment to run in |
| `aio-cli-version` | ❌ | string | `11.x.x` | Adobe I/O CLI version to install |
| `actions` | ✅ | string | | Newline-separated list of runtime action names to secure |

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

**Web-secure hash** — required:

| Name | Type | Description |
|------|------|-------------|
| `AIO_ACTION_AUTH_HASH` | Secret | Hash passed to `--web-secure` on each action. Callers may map a differently-named secret (e.g. `WHISK_AUTH_HASH`) to this when passing secrets explicitly. |

---

#### **Example Usage**

##### Securing specific actions after deployment

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

  secure:
    needs: deploy
    uses: aligent/workflows/.github/workflows/aio-secure-actions.yml@main
    with:
      environment: ${{ github.ref_name }}
      actions: |
        my-action
        another-action
    secrets: inherit
```

The GitHub Environment contains all required AIO secrets, with `AIO_ACTION_AUTH_HASH` holding the web-secure hash.

---

##### Mapping a differently-named secret

If the secret is stored under a different name (e.g. `WHISK_AUTH_HASH`), pass secrets explicitly rather than using `secrets: inherit`:

```yaml
  secure:
    needs: deploy
    uses: aligent/workflows/.github/workflows/aio-secure-actions.yml@main
    with:
      environment: production
      actions: |
        my-action
        another-action
    secrets:
      AIO_CLIENT_ID: ${{ secrets.AIO_CLIENT_ID }}
      AIO_CLIENT_SECRET: ${{ secrets.AIO_CLIENT_SECRET }}
      AIO_TECHNICAL_ACCOUNT_ID: ${{ secrets.AIO_TECHNICAL_ACCOUNT_ID }}
      AIO_TECHNICAL_ACCOUNT_EMAIL: ${{ secrets.AIO_TECHNICAL_ACCOUNT_EMAIL }}
      AIO_IMS_ORG_ID: ${{ secrets.AIO_IMS_ORG_ID }}
      AIO_SCOPES: ${{ secrets.AIO_SCOPES }}
      AIO_RUNTIME_NAMESPACE: ${{ secrets.AIO_RUNTIME_NAMESPACE }}
      AIO_RUNTIME_AUTH: ${{ secrets.AIO_RUNTIME_AUTH }}
      AIO_ACTION_AUTH_HASH: ${{ secrets.WHISK_AUTH_HASH }}
```
