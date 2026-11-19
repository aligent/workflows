# Coverage

Runs the test suite with coverage and posts the coverage tables as a comment on the pull request. The comment is updated in place on later runs instead of adding a new one.

#### **Inputs**
| Name            | Required | Type    | Default | Description                        |
|-----------------|----------|---------|---------|------------------------------------|
| package-manager | ❌       | string  | yarn    | Node package manager to use (`yarn` or `npm`) |
| is-yarn-classic | ❌       | boolean | false   | When `package-manager` is `yarn`, indicates the project uses a pre-Berry version of Yarn, which changes the install flags |
| node-version    | ❌       | string  | 24      | Node.js version to use when the repository has no `.nvmrc` file |
| test-command    | ❌       | string  | test    | Script (or Nx target) that runs the tests |
| comment-id      | ❌       | string  | default | Identifies this workflow's PR comment. Use a different value per call when the workflow runs more than once on a PR (e.g. a matrix). Letters, digits, `.`, `_` and `-` only |

#### **Node.js version**

If the calling repository has an `.nvmrc` file at its root, the version in it is used. Otherwise `node-version` is used (24 by default).

#### **How tests are run**

- **Nx workspace** (`nx.json` present): `nx run-many -t <test-command> --skip-nx-cache --outputStyle=stream -- --coverage`, using `yarn nx` or `npx nx`.
- **Yarn**: `yarn run <test-command> --coverage`
- **npm**: `npm run <test-command> -- --coverage`

#### **PR comment**

The comment holds the coverage tables from the test output, so the test runner must print the `text` coverage reporter. Jest and Vitest both do this by default. Only table rows are kept (the header, separators and rows with four numeric columns), and other output is ignored. In an Nx workspace each row keeps its project-name prefix; when projects run in parallel their rows can be interleaved. Tables longer than 60,000 characters are truncated.

The comment is posted even when tests fail, and is skipped when the workflow isn't running for a pull request. Each `comment-id` has its own comment, which later runs update in place.

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

**Several runs on one PR (one comment each):**
```yaml
jobs:
  coverage:
    strategy:
      matrix:
        suite: [unit, integration]
    permissions:
      contents: read
      pull-requests: write
    uses: aligent/workflows/.github/workflows/coverage.yml@main
    with:
      test-command: test:${{ matrix.suite }}
      comment-id: ${{ matrix.suite }}
```
