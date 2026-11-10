# AWS CDK

A streamlined AWS CDK workflow supporting multi-environment infrastructure synthesis, diffs and deployments with automatic package manager detection and Node.js version management.

#### **Features**
- **CDK synth → diff → deploy workflow**: Complete infrastructure deployment pipeline
- **Multi-environment support**: development, staging, and production deployments
- **Bootstrap validation**: Automatic CDK environment preparation and validation
- **Changeset preview**: CloudFormation diff analysis before deployment
- **PR diff comments**: When running a diff on a pull request, the result is posted (or updated) as a PR comment
- **Smart Node.js setup**: Automatic detection from .nvmrc file with dependency caching
- **Package manager detection**: Automatic support for npm, yarn (classic/berry), and pnpm
- **Cross-platform Docker builds**: ARM64 container support via native ARM runners
- **Debug support**: Verbose logging and debug output for troubleshooting
- **GitHub Environments support**: Credentials and stack names can be configured per-environment via GitHub Environment variables/secrets 

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| stack-name | ❌ | string | | CDK stack name (overrides `STACK_NAME` variable if provided) |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| role-session-name | ❌ | string | | AWS role session name for OIDC authentication (default: `{repo}-{short-sha}-{run-number}`) |
| github-environment | ❌ | string | Repository| GitHub Environment name for secrets/variables (e.g., Staging, Production) |
| **Deployment Control** |
| bootstrap | ❌ | boolean | false | Bootstrap CDK environment before deployment |
| deploy | ❌ | boolean | false | Deploy stack |
| diff | ❌ | boolean | false | Diff stack |
| synth | ❌ | boolean | false | Synth stack |
| **Advanced Configuration** |
| context-values | ❌ | string | {} | CDK context values as JSON object. Supports `$VAR` / `${VAR}` shell variable interpolation via `envsubst`. |
| environment-target | ❌ | string |  | Target environment for CDK context (stg/prd/dev) - passed as `--context environment=<value>` |
| extra-arguments | ❌ | string |  | Extra arguments as string. Supports `$VAR` / `${VAR}` shell variable interpolation via `envsubst`. |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |
| lfs | ❌ | boolean | false | Enable Git LFS support for checkout |
| runs-on | ❌ | string | ubuntu-latest | GitHub runner (use `ubuntu-24.04-arm` for native ARM64 builds) |
| **Custom CDK Commands** |
| bootstrap-command | ❌ | string | npx cdk bootstrap | Custom bootstrap command |
| synth-command | ❌ | string | npx cdk synth | Custom synth command |
| diff-command | ❌ | string | npx cdk diff | Custom diff command |
| deploy-command | ❌ | string | npx cdk deploy | Custom deploy command |
> **Note:** At least one of `synth`, `diff`, or `deploy` must be set to `true` for the workflow to run.

#### **Variables and Secrets**

These should be configured in your GitHub Environment (or at the repository level if not using environments).

| Name | Required | Type | Description |
|------|----------|------|-------------|
| `STACK_NAME` | ❌ | Variable | The name of the CloudFormation stack to deploy (required unless `stack-name` input is provided) |
| `AWS_ACCESS_KEY_ID` | ❌ | Variable | AWS Access Key ID (required for static credential auth) |
| `AWS_SECRET_ACCESS_KEY` | ❌ | Secret | AWS Secret Access Key (required for static credential auth) |
| `AWS_ROLE_ARN` | ❌ | Variable | AWS IAM role ARN (required for OIDC auth) |
| `CFN_EXECUTION_ROLE` | ❌ | Secret | CloudFormation execution role ARN (optional, for cross-account deployments with static credentials) |

> **Authentication:** Configure either static credentials (`AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`) **or** OIDC (`AWS_ROLE_ARN`). The workflow auto-detects which method to use.

**Extras** — optional:

| Name | Type | Description |
|------|------|-------------|
| `EXTRA_VARS` | Variable | Additional non-secret environment variables to inject into the deploy step |
| `EXTRA_SECRETS` | Secret | Additional secret environment variables to inject into the deploy step |

Both extra fields accept multiline `KEY=VALUE` pairs — one per line. Use these for runtime configuration that varies per project, such as feature flags.

#### **Outputs**
| Name | Description |
|------|-------------|
| stack-outputs | CloudFormation stack outputs as JSON |
| deployment-status | Deployment status (success/failed) |

#### **Example Usage**

**Bootstrap New Environment:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  bootstrap-staging:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      bootstrap: true
      aws-region: us-east-1
    secrets: inherit
```

**PR Diff (No Environment):**

> **Note:** `pull-requests: write` is required for the workflow to post diff comments on the PR.

```yaml
on:
  pull_request:
    branches:
      - '**'

permissions:
  pull-requests: write
  contents: read

jobs:
  diff:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      diff: true
    secrets: inherit
```

**PR Diff (Multiple Environments):**

- Each environment should have its own `STACK_NAME`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` configured.
- `github.base_ref` references the name of the target branch for staging and production.
- Each environment posts its own comment keyed on the stack name, so multiple diffs can coexist on the same PR.

```yaml
on:
  pull_request:
    branches:
      - '**'

permissions:
  pull-requests: write
  contents: read

jobs:
  diff-staging:
    if: github.base_ref == 'staging'
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      diff: true
    secrets: inherit

  diff-production:
    if: github.base_ref == 'production'
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Production
      diff: true
    secrets: inherit
```

**Staging Deployment:**
```yaml
on:
  push:
    branches:
      - staging

jobs: 
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      deploy: true
    secrets: inherit
```

**Production Deployment:**
```yaml
on:
  push:
    branches:
      - main

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Production
      deploy: true
    secrets: inherit
```

**Deploy Staging in NX Monorepo:**
```yaml
on:
  push:
    branches:
      - staging

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      deploy: true
      deploy-command: yarn nx run core:cdk deploy
      secrets: inherit
```

**Staging Deployment (OIDC):**

> **Note:** Calling workflows must set `permissions: id-token: write` at the workflow or job level for OIDC to function. Configure `AWS_ROLE_ARN` as a variable in your GitHub Environment.

```yaml
on:
  push:
    branches:
      - staging

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      deploy: true
    secrets: inherit
```

**Variable Interpolation in Context Values:**

`context-values` and `extra-arguments` support shell variable interpolation via `envsubst`. Variables are expanded after `EXTRA_VARS` and `EXTRA_SECRETS` are loaded into the environment, so you can reference any variable defined there.

> **Why is this needed?** GitHub Actions evaluates `${{ vars.* }}` expressions in the **caller's** context, which only has access to repository-level variables. Environment-scoped variables (configured via `github-environment`) are only available **inside** the reusable workflow at runtime. Variable interpolation bridges this gap, letting you reference environment-scoped values in `context-values` and `extra-arguments`.

```yaml
jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      deploy: true
      context-values: '{"api-url": "${API_BASE_URL}", "version": "${BUILD_VERSION}"}'
      extra-arguments: --tags project=${PROJECT_NAME}
    secrets: inherit
```

In this example, `API_BASE_URL`, `BUILD_VERSION`, and `PROJECT_NAME` would be set via `EXTRA_VARS` in the GitHub Environment.

**Deploy Production in NX Monorepo from Release:**
```yaml
on:
  release:
    types: [published]

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Production
      deploy: true
      deploy-command: yarn nx run core:cdk deploy
    secrets: inherit
```