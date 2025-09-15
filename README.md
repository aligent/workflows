# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

### AWS CDK Deployment

A streamlined AWS CDK deployment workflow supporting multi-environment infrastructure deployments with automatic package manager detection and Node.js version management.

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

#### **Inputs**
| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| **Core Configuration** |
| aws-region | ❌ | string | ap-southeast-2 | AWS region for deployment |
| cdk-stack-name | ✅ | string | | CDK stack name to deploy (required) |
| environment-target | ❌ | string | development | Target environment (staging/production/development) |
| **Deployment Control** |
| bootstrap-stack | ❌ | boolean | false | Bootstrap CDK environment before deployment |
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
| deployment-status | Deployment status (success/failed) |

#### **Example Usage**

**Basic Development Deployment:**
```yaml
jobs:
  deploy-dev:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-dev
      environment-target: development
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Production Deployment:**
```yaml
jobs:
  deploy-prod:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-prod
      environment-target: production
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

**Custom CDK Context:**
```yaml
jobs:
  deploy-custom:
    uses: aligent/workflows/.github/workflows/aws-cdk-deploy.yml@main
    with:
      cdk-stack-name: my-app-custom
      environment-target: staging
      context-values: '{"vpc-id": "vpc-12345", "environment": "staging"}'
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
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

#### **Secrets**
| Name                  | Required | Description                               |
|--------------------- |----------|--------------------------------------------|
| aws-access-key-id    | ✅       | AWS Access Key ID                          |
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
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
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
