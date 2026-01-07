# Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string   | yarn             | Node package manager to use       |
| has-env-vars    | ❌      | boolean  | false            | Whether environment variables are provided via ENV_VARS secret |
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

#### **Secrets**
| Name          | Required | Description                        |
|---------------|----------|-------------------------------------|
| NPM_TOKEN     | ❌      | NPM authentication token for private registries |
| ENV_VARS      | ❌      | Additional environment variables as key=value pairs (one per line) |

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
      has-env-vars: true
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      ENV_VARS: |
        BACKEND_URL=${{ secrets.BACKEND_URL }}
        API_KEY=${{ secrets.API_KEY }}
        NODE_ENV=test
```