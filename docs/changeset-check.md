# Changeset Check

Advisory PR check that detects when code changes affect publishable packages but no changeset file has been added. Posts a comment on the pull request reminding the developer to run `yarn changeset` (or equivalent). The comment is automatically removed when a changeset is added.

This check is **non-blocking** and will not prevent a PR from being merged.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| package-manager | No | string | yarn | Node package manager to use |
| is-yarn-classic | No | boolean | false | If Yarn (pre-Berry) should be used |
| pre-install-commands | No | string | | Commands to run before dependency installation (e.g., configure registries, auth tokens). `$NPM_TOKEN` is available as an environment variable. |
| packages-path | No | string | packages/ | Directory prefix containing publishable packages (e.g., `modules/`, `packages/`) |
| changeset-command | No | string | yarn changeset | Command developers should run to add a changeset (shown in PR comment) |
| changeset-status-command | No | string | yarn changeset status | Command to check changeset status (shown in PR comment tips) |
| comment-header | No | string | No Changeset Detected | Header text used to identify and update/delete the bot comment on PRs |
| debug | No | boolean | false | If debug flags should be set |

#### **Secrets**

| Name | Required | Description |
|------|----------|-------------|
| NPM_TOKEN | No | NPM authentication token for private registries |

#### How It Works

1. Checks out the repository (shallow clone is sufficient).
2. Sets up Node.js, Corepack, and installs dependencies.
3. Fetches the list of changed files from the GitHub API (`pulls.listFiles`), avoiding the need for full git history.
4. Determines which directories under `packages-path` have changed and reads each directory's `package.json` to get the real package name (handles cases where directory names differ from package names, e.g., `modules/core` contains `@aligent/take-flight`).
5. Checks if changeset files (`.changeset/*.md`, excluding `README.md`) exist.
6. If changeset files exist, marks the check as passing and removes any existing bot comment.
7. If no changesets exist but publishable packages are affected, posts a comment listing the affected packages with instructions on how to add a changeset.
8. The comment is automatically updated on subsequent pushes and removed entirely when a changeset is added.

#### Example Usage

**Basic usage (packages/ directory):**
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

**Custom packages path:**
```yaml
jobs:
  changeset-check:
    uses: aligent/workflows/.github/workflows/changeset-check.yml@main
    with:
      packages-path: "modules/"
```

**With private registry:**
```yaml
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
