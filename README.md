# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Documentation

| Workflow | Description |
|----------|-------------|
| [AWS CDK](docs/aws-cdk.md) | Multi-environment infrastructure synthesis, diffs and deployments with automatic package manager detection |
| [Changeset Check](docs/changeset-check.md) | Advisory PR comments when changesets are missing for affected packages |
| [Changeset Release](docs/changeset-release.md) | Automated package versioning and publishing with Changesets |
| [Gadget App Deployment](docs/gadget-deploy.md) | Gadget app deployment with push, test, and production deployment stages |
| [Magento Cloud Deployment](docs/magento-cloud-deploy.md) | Magento Cloud deployment with optional NewRelic monitoring and CST reporting |
| [Node Pull Request Checks](docs/node-pr.md) | Pull request quality checks for Node.js projects |
| [Nx Serverless Deployment](docs/nx-serverless-deployment.md) | Serverless deployment workflow for Nx monorepos |
| [PWA Deployment](docs/pwa-deployment.md) | Progressive Web Application deployment with S3 hosting, CloudFront CDN, multi-environment and multi-brand support |
| [PHP Quality Checks](docs/php-quality-checks.md) | Static analysis, coding standards validation, and testing with coverage reporting |
| [S3 Deployment](docs/s3-deploy.md) | Deploy assets to S3 buckets |
| [Update Lockfile](docs/update-lockfile.md) | Auto-commit lockfile updates on changeset version PRs |
| [Uptime Kuma](docs/uptime-kuma.md) | Pause and resume Uptime Kuma monitors during deployments |

## Adopting the Changeset Workflows

The three changeset workflows work together to automate package versioning, publishing, and PR hygiene. Each workflow's documentation includes inputs, secrets, setup instructions, and example caller YAML:
- [Changeset Release](docs/changeset-release.md) - creates version PRs and publishes packages
- [Changeset Check](docs/changeset-check.md) - advisory PR comments for missing changesets
- [Update Lockfile](docs/update-lockfile.md) - auto-commits lockfile updates on version PRs

## Local Development

### Prerequisites

**yamllint** (via pip3):
```bash
pip3 install yamllint
# Add pip's user bin to your PATH if not already present (macOS)
export PATH="$PATH:$(python3 -m site --user-base)/bin"
# Add the export to ~/.zshrc or ~/.bash_profile to make it permanent
```

**actionlint** — install the pre-built binary for your platform.
See the [actionlint install docs](https://github.com/rhysd/actionlint/blob/v1.7.11/docs/install.md) for all options. On macOS (Apple Silicon), download the `darwin-arm64` pre-built binary:

```bash
# macOS (Apple Silicon) — adjust version as needed
curl -sLO https://github.com/rhysd/actionlint/releases/download/v1.7.11/actionlint_1.7.11_darwin_arm64.tar.gz
tar -xzf actionlint_1.7.11_darwin_arm64.tar.gz actionlint
mv actionlint <somewhere on your $PATH>
```

**zizmor** — security analysis for GitHub Actions.
See the [zizmor install docs](https://docs.zizmor.sh/installation/) for all options:

```bash
pip3 install zizmor
```

**Task** — task runner used to execute the checks.
See [taskfile.dev/docs/installation](https://taskfile.dev/docs/installation) for all options:

```bash
# Install script — place the binary somewhere in your $PATH (e.g. ~/bin)
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b ~/bin
```

### Running checks locally

```bash
task          # run all checks
task yamllint # YAML linting only
task actionlint # GitHub Actions linting only
task zizmor   # security analysis only
```

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

