# Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use       |
| has-env-vars    | ❌      | boolean  | false            | Deprecated and ignored; ENV_VARS is used whenever it is set |
| is-yarn-classic   | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that the project uses a pre-Berry version of Yarn, which changes what flags we can pass to the command       |
| skip-cache      | ❌      | boolean  | false            | When `package-manager` is `yarn`, this can be used to indicate that we should use the `--force` flag to tell Yarn to ignore cache and fetch dependencies from the package repository       |
| pre-install-commands | ❌ | string | | Commands to run before dependency installation (e.g., configure registries, auth tokens) |
| build-command   | ❌      | string   | build            | Command to override the build command |
| test-command    | ❌      | string   | test             | Command to override the test command |
| lint-command    | ❌      | string   | lint             | Command to override the lint command |
| format-command  | ❌      | string   | format           | Command to override the format command |
| test-storybook-command | ❌ | string | test-storybook | Command to override the test-storybook command |
| check-types-command | ❌ | string | check-types | Command to override the check-types command |
| skip-build      | ❌      | boolean  | false            | If the build step should be skipped |
| skip-test       | ❌      | boolean  | false            | If the test step should be skipped |
| skip-lint       | ❌      | boolean  | false            | If the lint step should be skipped |
| skip-format     | ❌      | boolean  | false            | If the format step should be skipped |
| skip-test-storybook | ❌ | boolean | false | If the test-storybook step should be skipped |
| skip-check-types | ❌ | boolean | false | If the check-types step should be skipped |
| debug           | ❌      | boolean  | false            | If debug flags should be set |
| fetch-depth     | ❌      | number   | 1                | Number of commits to fetch. 0 indicates all history for all branches and tags |
| pre-test-command | ❌     | string   |                  | A script to run before the test checks (e.g., `generate:types`). Runs as: `<package-manager> run <command>` |
| node-options    | ❌      | string   |                  | Value for `NODE_OPTIONS` env var (e.g., `--max-old-space-size=4096`) |

#### **Nx Workspace Support**

This workflow automatically detects Nx workspaces and handles build commands appropriately:

- **Package.json scripts take priority**: If a command (e.g., `build`) exists in your `package.json` scripts, it will be executed using your package manager (e.g., `yarn run build`).
- **Nx targets as fallback**: If the command doesn't exist as a package.json script but exists as an Nx target, the workflow will use `npx nx run-many -t <command>` instead.
- **Skipped if not found**: If the command doesn't exist in either location, the step is skipped with an informational message.

This allows Nx monorepos to work seamlessly without needing custom build commands, while still respecting package.json scripts when they exist.

#### **Secrets**
| Name          | Required | Description                        |
|---------------|----------|-------------------------------------|
| NPM_TOKEN     | ❌      | NPM authentication token for private registries |
| ENV_VARS      | ❌      | Additional environment variables as `KEY=value` lines, with `KEY<<DELIMITER` blocks for multiline values like SSH keys (see [ENV_VARS format](#env_vars-format)) |

#### **ENV_VARS format**

`ENV_VARS` accepts the [`$GITHUB_ENV`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#setting-an-environment-variable) format, plus the legacy format described below. Set one variable per line:

```
BACKEND_URL=https://api.example.com
NODE_ENV=test
```

For multiline values (SSH keys, certificates, JSON), use a `KEY<<DELIMITER` block. Every line up to a line containing only the delimiter is the value:

```
DEPLOY_SSH_KEY<<SSH_KEY_EOF
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
SSH_KEY_EOF
```

All values are masked in the logs. Windows (CRLF) line endings are accepted, but carriage returns are removed and a warning is shown; re-save the secret with LF line endings to silence it.

**Legacy multiline format (deprecated):** a line that doesn't start with `KEY=` continues the previous variable's value:

```
DEPLOY_SSH_KEY=-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
```

This still works, but shows a warning. It can't tell a base64 line made only of letters and digits followed by `=` padding (for example `AAAABG5vbmU=`) from a new `KEY=value`, so such a line starts a new variable and cuts the value short. Use a `KEY<<DELIMITER` block instead.

#### Example Usage

**Basic usage:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      skip-format: false
```

**With private registry configuration:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**Multiple registry scopes:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      pre-install-commands: |
        yarn config set npmScopes.aligent.npmRegistryServer "https://npm.corp.aligent.consulting"
        yarn config set npmScopes.aligent.npmAuthToken "$NPM_TOKEN"
        yarn config set npmScopes.internal.npmRegistryServer "https://npm.internal.company.com"
        yarn config set npmScopes.internal.npmAuthToken "$NPM_TOKEN"
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**With additional environment variables:**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      ENV_VARS: |
        BACKEND_URL=${{ secrets.BACKEND_URL }}
        API_KEY=${{ secrets.API_KEY }}
        NODE_ENV=test
```

**With private Git dependency via SSH key (e.g., private GitHub/Bitbucket packages):**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: npm
      pre-install-commands: |
        mkdir -p ~/.ssh
        printenv DEPLOY_SSH_KEY > ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
    secrets:
      ENV_VARS: |
        DEPLOY_SSH_KEY<<SSH_KEY_EOF
        ${{ secrets.DEPLOY_SSH_KEY }}
        SSH_KEY_EOF
```

**BigCommerce Catalyst (requires code generation before checks):**
```yaml
jobs:
  pr-checks:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      package-manager: yarn
      pre-test-command: generate:types
      node-options: "--max-old-space-size=4096"
      check-types-command: typecheck
      skip-test: true
      skip-format: true
      skip-test-storybook: true
    secrets:
      ENV_VARS: |
        BIGCOMMERCE_STORE_HASH=${{ vars.BIGCOMMERCE_STORE_HASH }}
        BIGCOMMERCE_CHANNEL_ID=${{ vars.BIGCOMMERCE_CHANNEL_ID }}
        BIGCOMMERCE_STOREFRONT_TOKEN=${{ secrets.BIGCOMMERCE_STOREFRONT_TOKEN }}
```