# Coverage

Runs the test suite with coverage and posts the coverage tables as a comment on the pull request. The comment is updated in place on later runs instead of adding a new one.

#### **Inputs**
| Name            | Required | Type    | Default | Description                        |
|-----------------|----------|---------|---------|------------------------------------|
| package-manager | ❌       | string  | yarn    | Node package manager to use (`yarn` or `npm`) |
| is-yarn-classic | ❌       | boolean | false   | When `package-manager` is `yarn`, indicates the project uses a pre-Berry version of Yarn, which changes the install flags |
| node-version    | ❌       | string  | 24      | Node.js version to use when the repository has no `.nvmrc` file |
| test-command    | ❌       | string  | test    | Script (or Nx target) that runs the tests |

#### **Node.js version**

If the calling repository has an `.nvmrc` file at its root, the version in it is used. Otherwise `node-version` is used (24 by default).

#### **How tests are run**

- **Nx workspace** (`nx.json` present): `nx run-many -t <test-command> --skip-nx-cache --outputStyle=stream -- --coverage`, using `yarn nx` or `npx nx`.
- **Yarn**: `yarn run <test-command> --coverage`
- **npm**: `npm run <test-command> -- --coverage`

#### **PR comment**

The comment holds the coverage table rows from the test output, so the test runner must print the `text` coverage reporter. Jest and Vitest both do this by default. The comment is posted even when tests fail, and is skipped when the workflow isn't running for a pull request.

The calling job needs `pull-requests: write` permission. On pull requests from forks the token is read-only, so posting the comment fails.

#### Example Usage

**Yarn (default):**
```yaml
jobs:
  coverage:
    permissions:
      contents: read
      pull-requests: write
    uses: aligent/workflows/.github/workflows/coverage.yml@main
```

**npm with a fallback Node.js version:**
```yaml
jobs:
  coverage:
    permissions:
      contents: read
      pull-requests: write
    uses: aligent/workflows/.github/workflows/coverage.yml@main
    with:
      package-manager: npm
      node-version: "22"
```
