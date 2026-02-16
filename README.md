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
| [PHP Quality Checks](docs/php-quality-checks.md) | Static analysis, coding standards validation, and testing with coverage reporting |
| [S3 Deployment](docs/s3-deploy.md) | Deploy assets to S3 buckets |
| [Update Lockfile](docs/update-lockfile.md) | Auto-commit lockfile updates on changeset version PRs |

## Adopting the Changeset Workflows

The three changeset workflows (`changeset-release`, `changeset-check`, `update-lockfile`) work together to automate package versioning, publishing, and PR hygiene. This section explains how to adopt them in your project.

For a detailed technical overview including architecture diagrams and design decisions, see the [Changesets Shared Workflow Implementation Guide](../changesets-shared-workflow-implementation.md).

### Prerequisites

Your project needs Changesets configured before using these workflows:

1. Install the CLI and changelog plugin:
   ```bash
   yarn add -D @changesets/cli @changesets/changelog-github
   ```

2. Initialise Changesets (if not already done):
   ```bash
   npx changeset init
   ```

3. Configure `.changeset/config.json`:
   ```json
   {
     "$schema": "https://unpkg.com/@changesets/config@3.1.1/schema.json",
     "changelog": [
       "@changesets/changelog-github",
       { "repo": "aligent/your-repo-name" }
     ],
     "commit": false,
     "fixed": [],
     "linked": [],
     "access": "restricted",
     "baseBranch": "main",
     "updateInternalDependencies": "patch",
     "ignore": []
   }
   ```
   Set `"access": "public"` if publishing to the public npm registry.

4. Add convenience scripts to your root `package.json`:
   ```json
   {
     "scripts": {
       "changeset": "changeset",
       "changeset:version-and-install": "changeset version && yarn install --mode update-lockfile",
       "release": "your-publish-command"
     }
   }
   ```

### Adding the Caller Workflows

Create three workflow files in your project's `.github/workflows/` directory. Each one is a thin caller that references the shared workflow.

#### 1. Release Workflow

Runs on pushes to `main`. Creates version PRs when changesets are present, publishes packages when the version PR is merged.

**Public npm (minimal config):**
```yaml
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  release:
    uses: aligent/workflows/.github/workflows/changeset-release.yml@main
```

**Private Aligent registry:**
```yaml
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  release:
    uses: aligent/workflows/.github/workflows/changeset-release.yml@main
    with:
      publish-command: yarn release
      version-command: yarn changeset:version-and-install
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set enableGlobalCache false
      pre-publish-commands: |
        npm config set @aligent:registry https://npm.corp.aligent.consulting/
        npm config set //npm.corp.aligent.consulting/:_authToken $NPM_TOKEN
        yarn generate-types
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_PUBLISH_TOKEN }}
```

#### 2. Changeset Check

Runs on pull requests. Posts an advisory comment when code changes affect publishable packages but no changeset has been added. The comment is removed automatically once a changeset is added.

**Default packages/ directory:**
```yaml
name: Changeset Check

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  changeset-check:
    uses: aligent/workflows/.github/workflows/changeset-check.yml@main
```

**Custom packages path with private registry:**
```yaml
name: Changeset Check

on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  changeset-check:
    uses: aligent/workflows/.github/workflows/changeset-check.yml@main
    with:
      packages-path: "modules/"
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set enableGlobalCache false
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_PUBLISH_TOKEN }}
```

#### 3. Update Lockfile

Runs on pull requests when changeset or package.json files change. Automatically regenerates and commits the lockfile on version PRs created by the release workflow. Only acts on version PRs; all other PRs are skipped.

**Yarn Berry (default):**
```yaml
name: Update Lockfile

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - '.changeset/**'
      - 'packages/**/package.json'
      - 'package.json'

jobs:
  update-lockfile:
    uses: aligent/workflows/.github/workflows/update-lockfile.yml@main
```

**With private registry:**
```yaml
name: Update Lockfile

on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - '.changeset/**'
      - 'modules/**/package.json'
      - 'package.json'

jobs:
  update-lockfile:
    uses: aligent/workflows/.github/workflows/update-lockfile.yml@main
    with:
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set enableGlobalCache false
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_PUBLISH_TOKEN }}
```

### Configuring Secrets

Add these secrets in your GitHub repository settings (Settings > Secrets and variables > Actions):

| Secret | When Needed | Description |
|--------|-------------|-------------|
| `NPM_PUBLISH_TOKEN` | Private registry | Authentication token for the Aligent npm registry |
| `GITHUB_PAT` | Optional | A GitHub PAT if the default `GITHUB_TOKEN` is insufficient (e.g., triggering other workflows from changeset commits) |

The `GITHUB_TOKEN` provided automatically by GitHub Actions is used by default. A PAT is only needed if your version PR commits need to trigger other workflows.

### Adjusting the paths Filter

The `update-lockfile` workflow requires a `paths:` filter in your caller to avoid unnecessary runs. Adjust the glob to match your project's package directory:

- `packages/**/package.json` for projects using `packages/`
- `modules/**/package.json` for projects using `modules/`
- Add any other directories that contain publishable packages

### How the Release Flow Works

1. A developer opens a PR and adds a changeset via `yarn changeset`.
2. `changeset-check` verifies that affected packages have changesets and removes its advisory comment.
3. The PR is reviewed and merged to `main`.
4. `changeset-release` detects changeset files and creates (or updates) a **version PR** with bumped versions and updated changelogs.
5. `update-lockfile` regenerates the lockfile on the version PR so CI passes.
6. A maintainer reviews and merges the version PR.
7. `changeset-release` runs again, finds no changeset files, and **publishes** the packages.

No packages are published until the version PR is explicitly merged. This gives the team a chance to review version bumps and changelog entries before anything goes out.

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

