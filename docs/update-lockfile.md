# Update Lockfile

Automatically updates and commits the lockfile on changeset version PRs. When the `changesets/action` creates a version PR with bumped `package.json` versions, the lockfile becomes stale. This workflow detects version PRs by matching branch name or PR title patterns, regenerates the lockfile, and pushes the change back to the PR branch.

This workflow should be triggered by the caller on `pull_request` events with appropriate path filters.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| package-manager | No | string | yarn | Node package manager to use |
| is-yarn-classic | No | boolean | false | If Yarn (pre-Berry) should be used |
| pre-install-commands | No | string | | Commands to run before lockfile update (e.g., configure registries, auth tokens). `$NPM_TOKEN` is available as an environment variable. |
| lockfile | No | string | yarn.lock | Name of the lockfile to update and commit |
| update-command | No | string | yarn install --mode update-lockfile | Command to regenerate the lockfile without a full install |
| commit-message | No | string | chore: update lockfile after version bumps | Commit message for lockfile update |
| branch-pattern | No | string | changeset-release/ | Branch name pattern to match for version PRs |
| pr-title-pattern | No | string | chore: release packages | PR title pattern to match for version PRs |
| debug | No | boolean | false | If debug flags should be set |

#### **Secrets**

| Name | Required | Description |
|------|----------|-------------|
| NPM_TOKEN | No | NPM authentication token for private registries |
| GITHUB_PAT | No | GitHub PAT for pushing commits (uses GITHUB_TOKEN by default) |

#### How It Works

1. The workflow only runs on PRs that match the version PR pattern (by branch name containing `changeset-release/` or PR title containing `chore: release packages`). All other PRs are skipped.
2. Checks out the PR branch directly (not the merge commit) so changes can be pushed back. Full git history is not required.
3. Sets up Node.js, Corepack, and configures registry access.
4. Runs the lockfile update command (defaults to `yarn install --mode update-lockfile`).
5. If the lockfile has changed, commits and pushes it to the PR branch.
6. If the lockfile is already up to date, exits cleanly with no commit.

#### Important Notes

The **caller** is responsible for defining the `paths` filter in the `on.pull_request` trigger. This ensures the workflow only runs when relevant files change. A typical configuration:

```yaml
on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - '.changeset/**'
      - 'packages/**/package.json'  # Adjust to match your packages-path
      - 'package.json'
```

#### Example Usage

**Yarn Berry project:**
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

**Yarn Berry with private registry:**
```yaml
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

**npm project:**
```yaml
jobs:
  update-lockfile:
    uses: aligent/workflows/.github/workflows/update-lockfile.yml@main
    with:
      package-manager: npm
      lockfile: package-lock.json
      update-command: npm install --package-lock-only
```

**pnpm project:**
```yaml
jobs:
  update-lockfile:
    uses: aligent/workflows/.github/workflows/update-lockfile.yml@main
    with:
      package-manager: pnpm
      lockfile: pnpm-lock.yaml
      update-command: pnpm install --lockfile-only
```
