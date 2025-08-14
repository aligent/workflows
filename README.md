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

### Docker ECR Deployment

A comprehensive Docker container deployment workflow supporting multi-platform builds, ECR registry management, vulnerability scanning, and container security with build optimization and registry lifecycle management.

#### **Features**
- **Multi-platform builds**: Support for linux/amd64, linux/arm64, and ARM variants
- **ECR integration**: Automated ECR repository creation and lifecycle management  
- **Vulnerability scanning**: Trivy security scanning with configurable thresholds
- **Container signing**: Optional cosign-based image signing and attestation
- **Smart tagging**: Multiple tagging strategies (latest, semantic, branch, custom)
- **Build optimization**: Advanced caching with registry and inline cache support
- **Registry cleanup**: Automated cleanup of old images with retention policies
- **Multi-stage builds**: Support for target build stages and build arguments
- **Security gates**: Configurable vulnerability thresholds blocking insecure deployments

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
| **Security and Scanning** |
| vulnerability-scan | ❌ | boolean | true | Enable container vulnerability scanning |
| security-threshold | ❌ | string | HIGH | Security vulnerability threshold (CRITICAL/HIGH/MEDIUM/LOW) |
| **Tagging Strategy** |
| tag-strategy | ❌ | string | latest | Image tagging strategy (latest/semantic/branch/custom) |
| custom-tags | ❌ | string | | Custom tags (comma-separated) when using custom strategy |
| **Build Optimization** |
| cache-from | ❌ | string | | Cache sources for build optimization (comma-separated) |
| build-args | ❌ | string | {} | Docker build arguments as JSON object |
| target-stage | ❌ | string | | Target build stage for multi-stage Dockerfiles |
| **Registry Management** |
| cleanup-old-images | ❌ | boolean | false | Clean up old images from ECR registry |
| retention-count | ❌ | string | 10 | Number of images to retain when cleaning up |
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
| vulnerability-report | Container vulnerability scan results |

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

**Multi-platform with Vulnerability Scanning:**
```yaml
jobs:
  secure-deploy:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-secure-app
      platforms: "linux/amd64,linux/arm64"
      vulnerability-scan: true
      security-threshold: "CRITICAL"
      tag-strategy: "semantic"
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Production with Signing and Cleanup:**
```yaml
jobs:
  production-deploy:
    uses: aligent/workflows/.github/workflows/docker-ecr-deploy.yml@main
    with:
      ecr-repository: my-prod-app
      tag-strategy: "semantic"
      enable-signing: true
      cleanup-old-images: true
      retention-count: "5"
      security-threshold: "HIGH"
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

### BigCommerce Theme Deployment

A comprehensive BigCommerce Stencil theme deployment workflow supporting theme bundling, environment promotion, asset optimization, backup/restore capabilities, and multi-environment deployment with comprehensive validation.

#### **Features**
- **Stencil CLI integration**: Complete theme bundling, validation, and deployment pipeline
- **Multi-environment support**: Staging and production deployment workflows
- **Theme validation**: Bundle size checks, file permissions, and configuration validation
- **Asset optimization**: CSS/JS compression, image optimization, and bundle optimization
- **Backup & recovery**: Automatic current theme backup with rollback capabilities
- **Version management**: Theme versioning and deployment tracking
- **Environment templating**: Configuration management across environments
- **Security validation**: Theme structure validation and dependency auditing
- **Channel management**: Support for multi-channel theme deployment
- **Debug support**: Verbose logging and comprehensive error reporting

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| store-hash | ✅ | string | | BigCommerce store hash (10 character alphanumeric) |
| environment | ❌ | string | staging | Target environment (staging/production) |
| theme-name | ✅ | string | | Theme name for identification |
| **Deployment Control** |
| activate-theme | ❌ | boolean | true | Activate theme after successful deployment |
| bundle-optimization | ❌ | boolean | true | Enable theme asset optimization and compression |
| backup-current | ❌ | boolean | true | Backup current theme before deployment |
| **Technical Configuration** |
| node-version | ❌ | string | 18 | Node.js version for Stencil CLI environment |
| stencil-version | ❌ | string | | Pin specific Stencil CLI version (optional) |
| theme-config | ❌ | string | | Theme configuration as JSON object (optional) |
| **Theme Management** |
| variation-name | ❌ | string | | Specific theme variation to activate (optional) |
| channel-ids | ❌ | string | | Channel IDs for theme application (comma-separated) |
| apply-to-all-channels | ❌ | boolean | false | Apply theme to all store channels |
| delete-oldest | ❌ | boolean | false | Delete oldest theme to make room for new deployment |
| **Advanced Configuration** |
| debug | ❌ | boolean | false | Enable verbose logging and debug output |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| bigcommerce-access-token | ✅ | BigCommerce API access token with theme modify scope |
| bigcommerce-client-id | ✅ | BigCommerce API client ID |
| bigcommerce-client-secret | ✅ | BigCommerce API client secret |

#### **Outputs**
| Name | Description |
|------|-------------|
| theme-uuid | Deployed theme UUID from BigCommerce |
| theme-version | Deployed theme version identifier |
| deployment-url | BigCommerce store URL for theme verification |
| backup-created | Whether current theme backup was created |

#### **Example Usage**

**Basic Staging Deployment:**
```yaml
jobs:
  deploy-staging:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "abc123def4"
      environment: staging
      theme-name: "my-storefront-theme"
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Production Deployment with Custom Configuration:**
```yaml
jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "xyz789abc1"
      environment: production
      theme-name: "my-production-theme"
      activate-theme: true
      bundle-optimization: true
      backup-current: true
      variation-name: "Desktop"
      stencil-version: "6.15.0"
      node-version: "18"
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Multi-Channel Deployment:**
```yaml
jobs:
  deploy-multi-channel:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "def456ghi7"
      environment: staging
      theme-name: "multi-channel-theme"
      apply-to-all-channels: true
      delete-oldest: true
      theme-config: '{"logo": {"url": "https://cdn.example.com/logo.png"}, "colors": {"primary": "#ff6b35"}}'
      debug: true
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```

**Specific Channel Deployment:**
```yaml
jobs:
  deploy-specific-channels:
    uses: aligent/workflows/.github/workflows/bigcommerce-theme-deploy.yml@main
    with:
      store-hash: "ghi789jkl0"
      environment: production
      theme-name: "channel-specific-theme"
      channel-ids: "1,2,5"
      variation-name: "Mobile"
      bundle-optimization: false
      backup-current: false
    secrets:
      bigcommerce-access-token: ${{ secrets.BIGCOMMERCE_ACCESS_TOKEN }}
      bigcommerce-client-id: ${{ secrets.BIGCOMMERCE_CLIENT_ID }}
      bigcommerce-client-secret: ${{ secrets.BIGCOMMERCE_CLIENT_SECRET }}
```
