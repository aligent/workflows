# PHP Quality Checks

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