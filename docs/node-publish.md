# Node Publish Package

Builds, tests and publishes a Node.js package to npm using [OIDC trusted publishing](https://docs.npmjs.com/trusted-publishers). No long-lived npm publish token is required.

#### **How it works**

1. Checks the runner meets the trusted publishing requirements (npm >= 11.5.1, Node.js >= 22.14.0) and fails fast otherwise.
2. When triggered by a tag, checks the tag (with any leading `v` removed) matches the `package.json` version.
3. Installs dependencies with a frozen lockfile, then builds and tests using the configured package manager.
4. Runs the `prepublishOnly` script (if defined) and packs the package with the configured package manager, so `workspace:` / `catalog:` protocols and `publishConfig` overrides are applied.
5. Publishes the packed tarball with the npm CLI, which performs the OIDC token exchange and attaches provenance automatically.
6. Runs the `publish` and `postpublish` scripts (if defined), except on dry runs.

Dependency caching is disabled, as release builds should never use caches.

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use (`npm`, `yarn` or `pnpm`) |
| is-yarn-classic | ❌      | boolean  | false            | When `package-manager` is `yarn`, indicates the project uses a pre-Berry version of Yarn |
| pre-install-commands | ❌ | string | | Commands to run before dependency installation (e.g., configure registries, auth tokens) |
| build-command   | ❌      | string   | build            | Command to override the build command |
| test-command    | ❌      | string   | test             | Command to override the test command |
| skip-build      | ❌      | boolean  | false            | If the build step should be skipped |
| skip-test       | ❌      | boolean  | false            | If the test step should be skipped |
| package-directory | ❌    | string   | .                | Directory of the package to publish, relative to the repository root |
| registry-url    | ❌      | string   | https://registry.npmjs.org | Registry to publish to |
| dist-tag        | ❌      | string   |                  | npm dist-tag to publish under. When empty, derived from the `package.json` version (see below) |
| access          | ❌      | string   |                  | Package access level (`public` or `restricted`). Leave empty to use the registry default |
| skip-tag-version-check | ❌ | boolean | false          | If the check that the pushed tag matches the `package.json` version should be skipped |
| dry-run         | ❌      | boolean  | false            | If the package should be packed and validated without publishing |
| node-options    | ❌      | string   |                  | Value for `NODE_OPTIONS` env var (e.g., `--max-old-space-size=4096`) |

#### **Dist-tag resolution**

Unless `dist-tag` is set explicitly, it is derived from the `package.json` version so prereleases never move the `latest` tag:

| package.json version | Published version | Dist-tag |
|----------------------|-------------------|----------|
| `1.1.1`              | `1.1.1`           | `latest` |
| `1.2.0-beta.1`       | `1.2.0-beta.1`    | `beta`   |
| `2.0.0-rc.0+build.7` | `2.0.0-rc.0` (npm drops build metadata) | `rc` |
| `1.0.0-0`            | —                 | fails: set `dist-tag` explicitly |

The workflow fails before publishing if the resolved dist-tag does not start with a letter, as npm rejects dist-tags that are valid semver ranges.

#### **Secrets**
| Name          | Required | Description                        |
|---------------|----------|-------------------------------------|
| NPM_TOKEN     | ❌      | NPM authentication token for installing from private registries. Not used for publishing |

#### **Setting up trusted publishing**

1. Ensure `.nvmrc` uses a Node.js release that bundles npm >= 11.5.1 (e.g., a current Node.js 24 release).
2. On npmjs.com, open the package's **Settings → Trusted Publisher** and add a GitHub Actions publisher.
3. For **Workflow filename**, enter the consumer repository's **calling** workflow (e.g., `release.yml`), **not** `node-publish.yml`. npm validates against the workflow that invokes this reusable workflow.
4. Grant `id-token: write` in the calling workflow, as shown below.

The package must already exist on npm before a trusted publisher can be configured.

#### Example Usage

**Basic usage (publish on version tag):**
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  id-token: write
  contents: read

jobs:
  publish:
    uses: aligent/workflows/.github/workflows/node-publish.yml@main
    with:
      package-manager: npm
```

**pnpm monorepo package:**
```yaml
jobs:
  publish:
    uses: aligent/workflows/.github/workflows/node-publish.yml@main
    with:
      package-manager: pnpm
      package-directory: packages/my-package
      skip-tag-version-check: true
```

**With dependencies from a private registry:**
```yaml
jobs:
  publish:
    uses: aligent/workflows/.github/workflows/node-publish.yml@main
    with:
      package-manager: yarn
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Pre-release under a custom dist-tag** (overrides the derived `beta`/`rc` tag):
```yaml
jobs:
  publish:
    uses: aligent/workflows/.github/workflows/node-publish.yml@main
    with:
      package-manager: npm
      dist-tag: next
```
