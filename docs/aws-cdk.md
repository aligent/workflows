# AWS CDK

A streamlined AWS CDK workflow supporting multi-environment infrastructure synthesis, diffs and deployments with automatic package manager detection and Node.js version management.

#### **Features**
- **CDK synth → diff → deploy workflow**: Complete infrastructure deployment pipeline
- **Multi-environment support**: development, staging, and production deployments
- **Bootstrap validation**: Automatic CDK environment preparation and validation
- **Infrastructure validation**: Comprehensive stack validation and drift detection
- **Changeset preview**: CloudFormation diff analysis before deployment
- **Smart Node.js setup**: Automatic detection from .nvmrc file with dependency caching
- **Package manager detection**: Automatic support for npm, yarn (classic/berry), and pnpm
- **Debug support**: Verbose logging and debug output for troubleshooting
- **GitHub Environments support**: Credentials and stack names can be configured per-environment via GitHub Environment variables/secrets 

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| stack-name | ❌ | string | | CDK stack name (overrides `STACK_NAME` variable if provided) |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| github-environment | ❌ | string | Repository| GitHub Environment name for secrets/variables (e.g., Staging, Production) |
| **Deployment Control** |
| bootstrap | ❌ | boolean | false | Bootstrap CDK environment before deployment |
| deploy | ❌ | boolean | false | Deploy stack |
| diff | ❌ | boolean | false | Diff stack |
| synth | ❌ | boolean | false | Synth stack |
| **Advanced Configuration** |
| context-values | ❌ | string | {} | CDK context values as JSON object |
| environment-target | ❌ | string |  | Target environment for CDK context (stg/prd/dev) - passed as `--context environment=<value>` |
| extra-arguments | ❌ | string |  | Extra arguments as string |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |
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
| `AWS_ACCESS_KEY_ID` | ✅ | Variable | AWS Access Key ID for authentication |
| `AWS_SECRET_ACCESS_KEY` | ✅ | Secret | AWS Secret Access Key for authentication |
| `CFN_EXECUTION_ROLE` | ❌ | Secret | CloudFormation execution role ARN (optional, for cross-account deployments) |


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
```yaml
on:
  pull_request:
    branches:
      - '**'

jobs:
  diff:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      diff: true
    secrets: inherit
```

**PR Diff (Multiple Environments):**

To diff against both staging and production on every pull request, use separate jobs with different GitHub Environments. Each environment should have its own `STACK_NAME`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` configured.

```yaml
on:
  pull_request:
    branches:
      - '**'

jobs:
  diff-staging:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      github-environment: Staging
      diff: true
    secrets: inherit

  diff-production:
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