# Aligent GitHub Workflows

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Workflows

### Node Pull Request Checks

#### **Inputs**
| Name          | Required | Type    | Default            | Description                        |
|---------------|----------|---------|--------------------|------------------------------------|
| package-manager | ❌      | string  | yarn               | Node package manager to use       |
| build-command   | ❌      | string  | build              | Command to override the build command |
| test-command    | ❌      | string  | test               | Command to override the test command |
| lint-command    | ❌      | string  | lint               | Command to override the lint command |
| format-command  | ❌      | string  | format             | Command to override the format command |
| skip-build      | ❌      | boolean | false              | If the build step should be skipped |
| skip-test       | ❌      | boolean | false              | If the test step should be skipped |
| skip-lint       | ❌      | boolean | false              | If the lint step should be skipped |
| skip-format     | ❌      | boolean | false              | If the format step should be skipped |

#### Example Usage

```yaml
jobs:
  test-s3-deploy:
    uses: aligent/workflows/.github/workflows/node-pr.yml@main
    with:
      skip-format: false
```

### Nx Serverless Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                                |
|--------------------- |----------|---------|-----------------|-------------------------------------------|
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key                             |
| aws-secret-access-key| ✅       | string  |                 | AWS Secret Access Key                      |
| aws-profile          | ✅       | string  |                 | AWS Profile                                |
| aws-region           | ❌       | string  | ap-southeast-2  | AWS Region to deploy to                    |
| stage                | ✅       | string  |                 | Stage to deploy to                         |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

#### Example Usage

```yaml
jobs:
  deploy-serverless:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      aws-access-key-id: 123
      aws-secret-access-key: 456
      stage: development
      debug: true
```
