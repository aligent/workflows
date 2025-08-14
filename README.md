# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

### AWS CDK Deployment

A comprehensive AWS CDK deployment workflow supporting multi-environment infrastructure deployments, stack management, and infrastructure validation with approval gates.

#### **Features**
- **CDK synth → diff → deploy workflow**: Complete infrastructure deployment pipeline
- **Multi-environment support**: development, staging, and production deployments
- **Bootstrap validation**: Automatic CDK environment preparation and validation
- **Infrastructure validation**: Comprehensive stack validation and drift detection
- **Approval gates**: Manual approval workflows for production deployments
- **Changeset preview**: CloudFormation diff analysis before deployment
- **Rollback capabilities**: Support for stack destruction and rollback operations
- **Node.js optimization**: Configurable Node.js versions with dependency caching
- **Debug support**: Verbose logging and debug output for troubleshooting

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| cdk-stack-name | ✅ | string | | CDK stack name to deploy (required) |
| environment-target | ❌ | string | development | Target environment (staging/production/development) |
| **Deployment Control** |
| approval-required | ❌ | boolean | true | Require manual approval before deployment |
| destroy-mode | ❌ | boolean | false | Destroy stack instead of deploying |
| bootstrap-stack | ❌ | boolean | false | Bootstrap CDK environment before deployment |
| **Node.js and CDK Configuration** |
| node-version | ❌ | string | 18 | Node.js version to use |
| cdk-version | ❌ | string | | Pin specific CDK version (optional) |
| **Advanced Configuration** |
| context-values | ❌ | string | {} | CDK context values as JSON object |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-access-key-id | ✅ | AWS access key ID |
| aws-secret-access-key | ✅ | AWS secret access key |
| cfn-execution-role | ❌ | CloudFormation execution role ARN (optional, for cross-account deployments) |

#### **Outputs**
| Name | Description |
|------|-------------|
| stack-outputs | CloudFormation stack outputs as JSON |
| deployment-status | Deployment status (success/failed/destroyed) |

#### **Example Usage**

**Basic Development Deployment:**
```yaml
jobs:
  deploy-dev:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-dev
      environment-target: development
      approval-required: false
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Production Deployment with Manual Approval:**
```yaml
jobs:
  deploy-prod:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-prod
      environment-target: production
      approval-required: true
      node-version: "18"
      debug: true
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      cfn-execution-role: ${{ secrets.CFN_EXECUTION_ROLE }}
```

**Bootstrap New Environment:**
```yaml
jobs:
  bootstrap-staging:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-staging
      environment-target: staging
      bootstrap-stack: true
      aws-region: us-east-1
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Custom CDK Context and Version:**
```yaml
jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-custom
      environment-target: staging
      cdk-version: "2.100.0"
      context-values: '{"vpc-id": "vpc-12345", "environment": "staging"}'
      node-version: "20"
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Destroy Stack:**
```yaml
jobs:
  destroy-stack:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-old
      environment-target: development
      destroy-mode: true
      approval-required: false
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

### Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use       |
| is-yarn-classic   | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that the project uses a pre-Berry version of Yarn, which changes what flags we can pass to the command       |
| skip-cache      | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that we should use the `--force` flag to tell Yarn to ignore cache and fetch dependencies from the package repository       |
| build-command   | ❌      | string   | build            | Command to override the build command |
| test-command    | ❌      | string   | test             | Command to override the test command |
| lint-command    | ❌      | string   | lint             | Command to override the lint command |
| format-command  | ❌      | string   | format           | Command to override the format command |
| skip-build      | ❌      | boolean  | false            | If the build step should be skipped |
| skip-test       | ❌      | boolean  | false            | If the test step should be skipped |
| skip-lint       | ❌      | boolean  | false            | If the lint step should be skipped |
| skip-format     | ❌      | boolean  | false            | If the format step should be skipped |
| debug           | ❌      | boolean  | false            | If debug flags should be set |

#### Example Usage

```yaml
jobs:
  test-s3-deploy:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      skip-format: false
```

### Magento Cloud Deployment

A comprehensive Magento Cloud deployment workflow supporting multi-environment deployments, ECE patches, dependency injection compilation, NewRelic monitoring, and production approval gates.

#### **Features**
- **Multi-environment support**: integration, staging, and production deployments
- **PHP 8.1-8.3 support**: Magento-optimized container environments
- **ECE patches integration**: Automatic application of Magento Cloud patches
- **DI compilation**: Memory-optimized dependency injection compilation
- **NewRelic integration**: Deployment markers and performance monitoring
- **Production gates**: Manual approval workflow for production deployments
- **CST system integration**: Version reporting to centralized tracking systems
- **Full git history support**: Required for Magento Cloud deployment requirements
- **Health monitoring**: Post-deployment verification and performance checks

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Magento Cloud Configuration** |
| magento-cloud-project-id | ✅ | string | | Magento Cloud project ID (required) |
| environment | ❌ | string | integration | Target environment (integration/staging/production) |
| **PHP Configuration** |
| php-version | ❌ | string | 8.1 | PHP version for Magento (8.1, 8.2, 8.3) |
| memory-limit | ❌ | string | -1 | PHP memory limit for compilation (-1 for unlimited) |
| **Magento-specific Configuration** |
| apply-patches | ❌ | boolean | true | Apply ECE patches before deployment |
| di-compile | ❌ | boolean | true | Run dependency injection compilation |
| **Deployment Control** |
| manual-deploy | ❌ | boolean | false | Require manual approval for production deployments |
| **Monitoring and Reporting** |
| newrelic-app-id | ❌ | string | | NewRelic application ID for deployment markers (optional) |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| magento-cloud-cli-token | ✅ | Magento Cloud CLI token for authentication |
| newrelic-api-key | ❌ | NewRelic API key for deployment markers (optional) |
| cst-reporting-token | ❌ | CST system reporting token (optional) |

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
      php-version: "8.1"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Production Deployment with Manual Approval:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: production
      php-version: "8.2"
      manual-deploy: true
      newrelic-app-id: "123456789"
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
      newrelic-api-key: ${{ secrets.NEWRELIC_API_KEY }}
      cst-reporting-token: ${{ secrets.CST_REPORTING_TOKEN }}
```

**Staging Deployment with Custom PHP and Debug:**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: staging
      php-version: "8.3"
      memory-limit: "4G"
      debug: true
      apply-patches: true
      di-compile: true
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

**Skip ECE Patches and DI Compilation:**
```yaml
jobs:
  deploy-fast:
    uses: aligent/workflows/.github/workflows/magento-cloud-deploy.yml@main
    with:
      magento-cloud-project-id: abc123def456
      environment: integration
      apply-patches: false
      di-compile: false
      debug: true
    secrets:
      magento-cloud-cli-token: ${{ secrets.MAGENTO_CLOUD_CLI_TOKEN }}
```

### Nx Serverless Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                               |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key                             |
| aws-secret-access-key| ✅       | string  |                 | AWS Secret Access Key                      |
| cfn-role             | ✅       | string  |                 | AWS CFN Role to assume                     |
| aws-profile          | ✅       | string  |                 | AWS Profile                                |
| aws-region           | ❌       | string  | ap-southeast-2  | AWS Region to deploy to                    |
| stage                | ✅       | string  |                 | Stage to deploy to                         |
| environment          | ✅       | string  |                 | The GitHub environment to run in           |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

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
    secrets:
      aws-access-key-id: '123'
      aws-secret-access-key: '456'
```

### PHP Quality Checks

A comprehensive PHP quality assurance workflow supporting static analysis, coding standards validation, security auditing, and testing with coverage reporting across multiple PHP versions.

#### **Features**
- **PHPStan static analysis**: Configurable levels (1-9) with intelligent configuration detection
- **PHP CodeSniffer**: Support for Magento2, PSR12, and PSR2 coding standards
- **Composer security audit**: Automated vulnerability scanning of dependencies
- **PHPUnit testing**: Full test suite execution with coverage threshold enforcement
- **PHPMD mess detection**: Code quality analysis for maintainability issues
- **Multi-PHP support**: Matrix testing across PHP 8.1, 8.2, and 8.3
- **Smart caching**: Optimized Composer and analysis result caching
- **Parallel execution**: Concurrent quality checks for maximum efficiency
- **Flexible configuration**: Skip individual checks and customize tool behavior

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **PHP Configuration** |
| php-version | ❌ | string | 8.1 | PHP version to use (8.1, 8.2, 8.3) |
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
