# Changeset Release

Automated package versioning and publishing using [Changesets](https://github.com/changesets/changesets). This workflow uses the official `changesets/action` to create version PRs and publish packages to npm registries.

It operates in two phases:
1. **Version phase**: When changeset files exist, the action creates (or updates) a version PR containing bumped `package.json` versions, updated changelogs, and deleted changeset files.
2. **Publish phase**: When no changeset files exist (i.e., the version PR has been merged), the action runs the publish command to release packages to the registry.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| package-manager | No | string | yarn | Node package manager to use |
| is-yarn-classic | No | boolean | false | If Yarn (pre-Berry) should be used |
| pre-install-commands | No | string | | Commands to run before dependency installation (e.g., configure registries, auth tokens). `$NPM_TOKEN` is available as an environment variable. |
| pre-publish-commands | No | string | | Commands to run after install but before the changesets action (e.g., build, generate-types, run tests) |
| publish-command | No | string | yarn changeset publish | Command to publish packages. Override this for hybrid setups (e.g., `yarn release` calling `nx release publish`). |
| version-command | No | string | yarn changeset version | Command to version packages. Override this if you need a post-version step (e.g., lockfile update). |
| pr-title | No | string | chore: release packages | Title for the version PR created by changesets |
| commit-message | No | string | chore: release packages | Commit message used by changesets when versioning |
| create-github-releases | No | boolean | true | Whether to create GitHub Releases when publishing |
| npm-registry-url | No | string | | npm registry URL for setup-node (used for OIDC/token-based npm publishing). Leave empty if not needed. |
| post-publish-commands | No | string | | Commands to run after a successful publish (e.g., notifications, cache invalidation) |
| debug | No | boolean | false | If debug flags should be set |

#### **Secrets**

| Name | Required | Description |
|------|----------|-------------|
| NPM_TOKEN | No | NPM authentication token for private registries (used during install and publishing) |
| GITHUB_PAT | No | GitHub PAT if the default GITHUB_TOKEN is insufficient (e.g., for triggering other workflows from changeset commits). Falls back to `github.token` if not provided. |

#### How It Works

1. Checks out the repository. Changelog entries with PR links are generated via the GitHub API by `@changesets/changelog-github`, so full git history is not required.
2. Sets up Node.js from `.nvmrc`, enables Corepack if `packageManager` is set in `package.json`, and configures the dependency cache.
3. Runs any `pre-install-commands` (typically registry configuration and auth tokens).
4. Installs dependencies using the configured package manager with a locked install.
5. Runs any `pre-publish-commands` (build steps, type generation, tests).
6. Configures Git as `github-actions[bot]` for version commits.
7. Runs `changesets/action@v1.6.0` which either:
   - Creates/updates a version PR (when changeset files are present), or
   - Publishes packages to the registry (when no changeset files are present).
8. Prints published package names and versions if a publish occurred.
9. Runs any `post-publish-commands` after a successful publish.

#### Prerequisites

Your project needs Changesets configured before using this workflow:

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

#### How the Release Flow Works

The three changeset workflows (`changeset-release`, [changeset-check](changeset-check.md), [update-lockfile](update-lockfile.md)) work together:

1. A developer opens a PR and adds a changeset via `yarn changeset`.
2. `changeset-check` verifies that affected packages have changesets and removes its advisory comment.
3. The PR is reviewed and merged to `main`.
4. `changeset-release` detects changeset files and creates (or updates) a **version PR** with bumped versions and updated changelogs.
5. `update-lockfile` regenerates the lockfile on the version PR so CI passes.
6. A maintainer reviews and merges the version PR.
7. `changeset-release` runs again, finds no changeset files, and **publishes** the packages.

No packages are published until the version PR is explicitly merged. This gives the team a chance to review version bumps and changelog entries before anything goes out.

#### Example Usage

**Basic usage (public npm, default commands):**
```yaml
name: Release

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  release:
    uses: aligent/workflows/.github/workflows/changeset-release.yml@main
```

**Private registry with pre-install commands:**
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
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set enableGlobalCache false
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_PUBLISH_TOKEN }}
```

**Hybrid approach (Changesets for versioning, nx release publish for publishing):**
```yaml
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

**With pre-publish build and test steps:**
```yaml
jobs:
  release:
    uses: aligent/workflows/.github/workflows/changeset-release.yml@main
    with:
      npm-registry-url: https://registry.npmjs.org/
      pre-publish-commands: |
        yarn nx run-many --target=build --all
        yarn nx run-many --target=test --all
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```
