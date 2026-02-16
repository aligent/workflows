# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Documentation

| Workflow | Description |
|----------|-------------|
| [AWS CDK](docs/aws-cdk.md) | Multi-environment infrastructure synthesis, diffs and deployments with automatic package manager detection |
| [Gadget App Deployment](docs/gadget-deploy.md) | Gadget app deployment with push, test, and production deployment stages |
| [Magento Cloud Deployment](docs/magento-cloud-deploy.md) | Magento Cloud deployment with optional NewRelic monitoring and CST reporting |
| [Node Pull Request Checks](docs/node-pr.md) | Pull request quality checks for Node.js projects |
| [Nx Serverless Deployment](docs/nx-serverless-deployment.md) | Serverless deployment workflow for Nx monorepos |
| [PHP Quality Checks](docs/php-quality-checks.md) | Static analysis, coding standards validation, and testing with coverage reporting |
| [S3 Deployment](docs/s3-deploy.md) | Deploy assets to S3 buckets |
| [Uptime Kuma](docs/uptime-kuma.md) | Pause and resume Uptime Kuma monitors during deployments |

## Test Github Workflows Locally using Act

Refer to https://aligent.atlassian.net/wiki/x/JgDjAwE on guidance to test these Workflows locally

## CST Reporting Configuration

The CST (Confidentiality and Security Team) reporting feature can be configured in two ways:

1. **Workspace-level configuration (recommended):**
   - Set `CST_ENDPOINT` as a repository/organization variable (base URL, e.g., `https://package.report.aligent.consulting`)
   - Set `CST_PROJECT_KEY` as a repository/organization variable (your project identifier, defaults to the repository name if not set)
   - Set `CST_REPORTING_TOKEN` as a repository/organization secret
   - The workflow will automatically use these when available

2. **Input overrides (optional):**
   - Use `cst-endpoint` input to override the workspace variable (base URL)
   - Use `cst-project-key` input to override the workspace variable (project identifier)
   - Use `cst-reporting-key` input to override the workspace secret
   - Useful for testing or special deployments

The workflow constructs the full CST URL as: `{endpoint}/{project-key}`

CST reporting only runs when deploying from the target branch (defaults to the repository's default branch, overridable via `cst-branch` input) and when endpoint, project key, and auth key are all configured. If any are missing or the branch doesn't match, the step is skipped with an informational message.

