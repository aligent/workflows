# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

### AWS CDK

A streamlined AWS CDK workflow supporting multi-environment infrastructure synthesis, diffs and deployments with automatic package manager detection and Node.js version management.

#### **Features**
- **CDK synth → diff → deploy workflow**: Complete infrastructure deployment pipeline
- **Multi-environment support**: development, staging, and production deployments
- **Bootstrap validation**: Automatic CDK environment preparation and validation
- **Infrastructure validation**: Comprehensive stack validation and drift detection
- **Changeset preview**: CloudFormation diff analysis before deployment
- **Rollback capabilities**: Support for stack destruction and rollback operations
- **Smart Node.js setup**: Automatic detection from .nvmrc file with dependency caching
- **Package manager detection**: Automatic support for npm, yarn (classic/berry), and pnpm
- **Debug support**: Verbose logging and debug output for troubleshooting
- **Stack name**: Variable can be defined per Environment 

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| cdk-stack-name | ✅ | string | | CDK stack name to deploy (required) |
| environment-target | ❌ | string |  | Target environment (stg/prd/dev/"") |
| aws-access-key-id | ✅ | string | | AWS access key ID |
| **Deployment Control** |
| bootstrap | ❌ | boolean | false | Bootstrap CDK environment before deployment |
| deploy | ❌ | boolean | false | Deploy stack |
| diff | ❌ | boolean | false | Diff stack |
| synth | ❌ | boolean | false | Synth stack |
| **Advanced Configuration** |
| context-values | ❌ | string | {} | CDK context values as JSON object |
| extra-arguments | ❌ | string |  | Extra arguments as string |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |
| **Custom CDK Commands** |
| bootstrap-command | ❌ | string | npx cdk bootstrap | Custom bootstrap command |
| synth-command | ❌ | string | npx cdk synth | Custom synth command |
| diff-command | ❌ | string | npx cdk diff | Custom diff command |
| deploy-command | ❌ | string | npx cdk deploy | Custom deploy command |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-secret-access-key | ✅ | AWS secret access key |
| cfn-execution-role | ❌ | CloudFormation execution role ARN (optional, for cross-account deployments) |

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
      cdk-stack-name: ${{ vars.STACK_NAME }}
      bootstrap: true
      aws-region: us-east-1
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**PR synth and diff:**
```yaml
on:
  pull_request:
    branches:
      - '**'

...

jobs:
  diff-synth:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      diff: true
      synth: true
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Staging Deployment:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      deploy: true
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Production Deployment:**
```yaml
on:
  push:
    branches:
      - production

...

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      deploy: true
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Deploy Staging and Production:**
```yaml
on:
  push:
    branches:
      - staging
      - production

...

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      deploy: true
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Deploy Staging in NX Monorepo:**
```yaml
on:
  push:
    branches:
      - staging

...

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/aws-cdk.yml@main
    with:
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      deploy: true
      deploy-command: yarn nx run core:cdk deploy
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
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
      cdk-stack-name: ${{ vars.STACK_NAME }}
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
      deploy: true
      deploy-command: yarn nx run core:cdk deploy
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Docker ECR Deployment

A comprehensive Docker container deployment workflow supporting multi-platform builds, ECR registry management, and container signing with build optimization. 

**Important:** The ECR repository must exist before running this workflow - the workflow will fail if the repository doesn't exist.

#### **Features**
- **Multi-platform builds**: Support for linux/amd64, linux/arm64, and ARM variants
- **ECR integration**: Push images to existing ECR repositories  
- **Container signing**: Optional cosign-based image signing and attestation
- **Smart tagging**: Multiple tagging strategies (latest, semantic, branch, custom)
- **Build optimization**: Advanced caching with registry and inline cache support
- **Multi-stage builds**: Support for target build stages and build arguments

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for ECR registry |
| ecr-repository | ✅ | string | | ECR repository name (required) |
| dockerfile-path | ❌ | string | Dockerfile | Path to Dockerfile |
| build-context | ❌ | string | . | Docker build context path |
| **Platform and Build Configuration** |
| platforms | ❌ | string | linux/amd64,linux/arm64 | Target platforms for multi-platform builds |
| push-to-registry | ❌ | boolean | true | Push built images to ECR registry |
| **Tagging Strategy** |
| tag-strategy | ❌ | string | latest | Image tagging strategy (latest/semantic/branch/custom) |
| custom-tags | ❌ | string | | Custom tags (comma-separated) when using custom strategy |
| **Build Optimization** |
| cache-from | ❌ | string | | Cache sources for build optimization (comma-separated) |
| build-args | ❌ | string | {} | Docker build arguments as JSON object |
| target-stage | ❌ | string | | Target build stage for multi-stage Dockerfiles |
| **Container Signing** |
| enable-signing | ❌ | boolean | false | Enable container image signing with cosign |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-access-key-id | ✅ | AWS access key ID |
| aws-secret-access-key | ✅ | AWS secret access key |
| container-signing-key | ❌ | Private key for container signing (optional) |

#### **Outputs**
| Name | Description |
|------|-------------|
| image-uri | Full URI of the built container image |
| image-digest | SHA256 digest of the built image |
| image-tags | Applied image tags as JSON array |

#### **Example Usage**

**Basic Docker Build and Push:**
```yaml
jobs:
  docker-deploy:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-app
      dockerfile-path: Dockerfile
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Multi-platform with Semantic Tagging:**
```yaml
jobs:
  multi-platform-deploy:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-app
      platforms: "linux/amd64,linux/arm64"
      tag-strategy: "semantic"
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Production with Signing:**
```yaml
jobs:
  production-deploy:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-prod-app
      tag-strategy: "semantic"
      enable-signing: true
      aws-region: "us-east-1"
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      container-signing-key: ${{ secrets.COSIGN_PRIVATE_KEY }}
```

**Custom Build with Optimization:**
```yaml
jobs:
  optimized-build:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-optimized-app
      build-context: "./backend"
      dockerfile-path: "./backend/Dockerfile.prod"
      target-stage: "production"
      build-args: '{"NODE_ENV": "production", "API_VERSION": "v2"}'
      cache-from: "my-optimized-app:buildcache,my-base-image:latest"
      tag-strategy: "custom"
      custom-tags: "latest,v2.1.0,production"
      debug: true
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use       |
| has-env-vars    | ❌      | boolean  | false            | Whether environment variables are provided via ENV_VARS secret |
| is-yarn-classic   | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that the project uses a pre-Berry version of Yarn, which changes what flags we can pass to the command       |
| skip-cache      | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that we should use the `--force` flag to tell Yarn to ignore cache and fetch dependencies from the package repository       |
| pre-install-commands | ❌ | string | | Commands to run before dependency installation (e.g., configure registries, auth tokens) |
| build-command   | ❌      | string   | build            | Command to override the build command |
| test-command    | ❌      | string   | test             | Command to override the test command |
| lint-command    | ❌      | string   | lint             | Command to override the lint command |
| format-command  | ❌      | string   | format           | Command to override the format command |
| test-storybook-command | ❌ | string | test-storybook | Command to override the test-storybook command |
| check-types-command | ❌ | string | check-types | Command to override the check-types command |
| skip-build      | ❌      | boolean  | false            | If the build step should be skipped |
| skip-test       | ❌      | boolean  | false            | If the test step should be skipped |
| skip-lint       | ❌      | boolean  | false            | If the lint step should be skipped |
| skip-format     | ❌      | boolean  | false            | If the format step should be skipped |
| skip-test-storybook | ❌ | boolean | false | If the test-storybook step should be skipped |
| skip-check-types | ❌ | boolean | false | If the check-types step should be skipped |
| debug           | ❌      | boolean  | false            | If debug flags should be set |

#### **Secrets**
| Name          | Required | Description                        |
|---------------|----------|-------------------------------------|
| NPM_TOKEN     | ❌      | NPM authentication token for private registries |
| ENV_VARS      | ❌      | Additional environment variables as key=value pairs (one per line) |

#### Example Usage

**Basic usage:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      skip-format: false
```

**With private registry configuration:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Multiple registry scopes:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set npmScopes.internal.npmRegistryServer "https://npm.internal.company.com"
        yarn config set npmScopes.internal.npmAuthToken "$NPM_TOKEN"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**With additional environment variables:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      has-env-vars: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      ENV_VARS: |
        BACKEND_URL=${{ secrets.BACKEND_URL }}
        API_KEY=${{ secrets.API_KEY }}
        NODE_ENV=test
```

### S3 Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                               |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-region           | ❌       | string  | ap-southeast-2  | AWS region                                 |
| s3-bucket            | ✅       | string  |                 | Name of the S3 bucket                      |
| s3-path              | ❌       | string  |                 | Path in the S3 bucket                      |
| local-path           | ✅       | string  |                 | Path to deploy                             |
| delete-flag          | ❌       | boolean | true            | Enable --delete flag                       |
| cache-control        | ❌       | string  |                 | Cache control headers                      |
| extra-args           | ❌       | string  |                 | Additional AWS CLI args                    |
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key ID                          |

#### **Secrets**
| Name                  | Required | Description                               |
|--------------------- |----------|--------------------------------------------|
| aws-secret-access-key| ✅       | AWS Secret Access Key                      |

#### Example Usage

```yaml
jobs:
  deploy-to-s3:
    uses: aligent/workflows/.github/workflows/s3-deploy.yml@main
    with:
      s3-bucket: my-bucket
      local-path: ./dist
      s3-path: /public
      cache-control: "max-age=3600"
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Magento Cloud Deployment

A simple Magento Cloud deployment workflow that pushes code to your Magento Cloud git repository with optional NewRelic monitoring and CST reporting.

#### **Features**
- **Multi-environment support**: integration, staging, and production deployments
- **Simple git push**: No composer install, patching, or building - just pushes code
- **NewRelic integration**: Optional deployment markers for tracking deployment lifecycle (start/complete)
- **CST system integration**: Optional composer.lock reporting to Confidentiality and Security Team
- **Environment protection**: Uses GitHub environment protection rules for deployment gates
- **Full git history support**: Required for Magento Cloud deployment requirements
- **Parallel post-deployment**: NewRelic completion and CST reporting run in parallel for efficiency

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Magento Cloud Configuration** |
| magento-cloud-project-id | ✅ | string | | Magento Cloud project ID (required) |
| environment | ❌ | string | integration | Target environment (integration/staging/production) |
| **Monitoring and Reporting** |
| newrelic-app-id | ❌ | string | | NewRelic application ID for deployment markers (optional) |
| **CST Reporting Configuration** |
| cst-endpoint | ❌ | string | | CST endpoint base URL (optional, overrides workspace variable) |
| cst-project-key | ❌ | string | | CST project key (optional, overrides workspace variable) |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| magento-cloud-cli-token | ✅ | Magento Cloud CLI token for authentication |
| newrelic-api-key | ❌ | NewRelic API key for deployment markers (optional) |
| cst-reporting-token | ❌ | CST reporting token (workspace-level secret, optional) |

#### **Workspace Variables (Optional)**
| Name | Description |
|------|-------------|
| CST_ENDPOINT | CST endpoint base URL (e.g., `https://package.report.aligent.consulting`) |
| CST_PROJECT_KEY | CST project identifier for your organization |

#### **Outputs**
| Name | Description |
|------|-------------|
| deployment-url | URL of the deployed Magento application |
| deployment-id | Magento Cloud deployment ID |

#### **Example Usage**

**Basic Integration Deployment:**
```yaml
jobs:
  deploy-integration:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: integration
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Production Deployment with NewRelic Monitoring:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: production
      newrelic-app-id: "123456789"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
      newrelic-api-key: ${{ secrets.NEWRELIC_API_KEY }}
```

**Staging Deployment with CST Reporting:**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: staging
      debug: true
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Deployment with CST Reporting Override:**
```yaml
jobs:
  deploy-with-cst:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: staging
      cst-endpoint: "https://package.report.aligent.consulting"
      cst-project-key: "your-project-key"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
      cst-reporting-token: ${{ secrets.CST_REPORTING_TOKEN }}
```

#### **CST Reporting Configuration**

The CST (Confidentiality and Security Team) reporting feature can be configured in two ways:

1. **Workspace-level configuration (recommended):**
   - Set `CST_ENDPOINT` as a repository/organization variable (base URL, e.g., `https://package.report.aligent.consulting`)
   - Set `CST_PROJECT_KEY` as a repository/organization variable (your project identifier)
   - Set `CST_REPORTING_TOKEN` as a repository/organization secret
   - The workflow will automatically use these when available

2. **Input overrides (optional):**
   - Use `cst-endpoint` input to override the workspace variable (base URL)
   - Use `cst-project-key` input to override the workspace variable (project identifier)
   - Use `cst-reporting-key` input to override the workspace secret
   - Useful for testing or special deployments

The workflow constructs the full CST URL as: `{endpoint}/{project-key}/adobe-commerce`

CST reporting only runs when endpoint, project key, and auth key are all configured. If any are missing, the step is skipped with an informational message.
### Nx Serverless Deployment

#### **Inputs**
| Name                 | Required | Type    | Default         | Description                                |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key                             |
| cfn-role             | ✅       | string  |                 | AWS CFN Role to assume                     |
| aws-profile          | ✅       | string  |                 | AWS Profile                                |
| aws-region           | ❌       | string  | ap-southeast-2  | AWS Region to deploy to                    |
| stage                | ✅       | string  |                 | Stage to deploy to                         |
| environment          | ✅       | string  |                 | The GitHub environment to run in           |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-secret-access-key | ✅ | AWS secret access key |

#### Example Usage

```yaml
jobs:
  deploy-serverless:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      aws-profile: my-profile
      stage: dev
      environment: development
      debug: true
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### PHP Quality Checks

A comprehensive PHP quality assurance workflow supporting static analysis, coding standards validation, and testing with coverage reporting across multiple PHP versions.

#### **Features**
- **PHPStan static analysis**: Configurable levels (1-9) with intelligent configuration detection
- **PHP CodeSniffer**: Support for Magento2, PSR12, and PSR2 coding standards
- **PHPUnit testing**: Full test suite execution with coverage threshold enforcement
- **Multi-PHP support**: Compatible with PHP 8.1, 8.2, and 8.3
- **Smart caching**: Optimized Composer and analysis result caching
- **Parallel execution**: Concurrent quality checks for maximum efficiency
- **Flexible configuration**: Skip individual checks and customize tool behavior

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **PHP Configuration** |
| php-version | ✅ | string | | PHP version to use (8.1, 8.2, 8.3) |
| memory-limit | ❌ | string | 512M | PHP memory limit for analysis tools |
| **PHPStan Configuration** |
| phpstan-level | ❌ | string | 6 | PHPStan analysis level (1-9) |
| skip-phpstan | ❌ | boolean | false | Skip PHPStan static analysis |
| **Code Style Configuration** |
| coding-standard | ❌ | string | Magento2 | Coding standard (Magento2, PSR12, PSR2) |
| skip-phpcs | ❌ | boolean | false | Skip PHP CodeSniffer checks |
| **Testing Configuration** |
| coverage-threshold | ❌ | string | 80 | Code coverage threshold percentage (0-100) |
| skip-tests | ❌ | boolean | false | Skip PHP unit testing |
| **Composer Configuration** |
| composer-args | ❌ | string |  | Additional composer install arguments |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Example Usage**

**Basic Quality Checks:**
```yaml
jobs:
  quality-check:
    uses: aligent/workflows/.github/workflows/php-quality-checks.yml@main
    with:
      php-version: "8.2"
      phpstan-level: "7"
```

**Magento 2 Project with Custom Standards:**
```yaml
jobs:
  magento-quality:
    uses: aligent/workflows/.github/workflows/php-quality-checks.yml@main
    with:
      php-version: "8.1"
      coding-standard: "Magento2"
      phpstan-level: "6"
      coverage-threshold: "75"
      memory-limit: "1G"
      debug: true
```

**Skip Specific Checks:**
```yaml
jobs:
  custom-checks:
    uses: aligent/workflows/.github/workflows/php-quality-checks.yml@main
    with:
      php-version: "8.3"
      skip-phpcs: true
      skip-tests: true
      phpstan-level: "9"
```

**PSR Standards with High Coverage:**
```yaml
jobs:
  strict-quality:
    uses: aligent/workflows/.github/workflows/php-quality-checks.yml@main
    with:
      php-version: "8.2"
      coding-standard: "PSR12"
      phpstan-level: "8"
      coverage-threshold: "90"
      composer-args: "--no-dev"
```

### Gadget App Deployment

A comprehensive Gadget app deployment workflow supporting push, test, and production deployment stages with multi-environment management.

#### **Features**
- **Custom-environment support**: Support for custom development environment name
- **Conditional automated testing**: Automatic test execution controlled by boolean flag
- **Conditional deployment**: Production deployment controlled by boolean flag
- **Force push capabilities**: Ensures code synchronization with `--force` flag
- **Gadget CLI integration**: Uses `ggt` CLI tool for all operations
- **Test validation**: Runs full test suite before production deployment

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| app-name | ✅ | string | | Gadget App name to deploy to (required) |
| test | ❌ | boolean | false | Enable testing on development environment (true/false) |
| deploy-production | ❌ | boolean | false | Enable production deployment (true/false) |
| **Environment Configuration** |
| environment-name | ❌ | string | staging | Main development environment name |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| gadget-api-token | ✅ | Gadget API authentication token |

#### **Outputs**
| Name | Description |
|------|-------------|
| push-environment-status | Status of test environment push (success/failure) |

#### **Example Usage**

**Push to Staging Only:**
```yaml
jobs:
  push-staging:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

**Push with Testing:**
```yaml
jobs:
  push-and-test:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      test: true
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

**Full Deployment Pipeline (Push, Test, Deploy):**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      test: true
      deploy-production: true
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```

**Push to custom Environment Name:**
```yaml
jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/gadget-deploy.yml@main
    with:
      app-name: my-gadget-app
      environment-name: development
    secrets:
      gadget-api-token: ${{ secrets.GADGET_API_TOKEN }}
```
