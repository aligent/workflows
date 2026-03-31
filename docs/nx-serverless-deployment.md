# Nx Serverless Deployment

#### **Inputs**
| Name                 | Required | Type    | Default         | Description                                |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| environment          | ✅       | string  |                 | The GitHub environment to run in           |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

#### **Variables and Secrets**

These should be configured in your GitHub Environment (or at the repository level if not using environments).

| Name | Required | Type | Description |
|------|----------|------|-------------|
| `STAGE` |  ✅ | Variable | The Stage name to deploy |
| `AWS_ACCESS_KEY_ID` | ✅ | Variable | AWS Access Key ID for authentication |
| `AWS_SECRET_ACCESS_KEY` | ✅ | Secret | AWS Secret Access Key for authentication |
| `CFN_ROLE` | ✅ | Secret | CloudFormation role ARN to assume |
| `AWS_REGION` | ❌ | Variable | AWS Region to deploy to (defaults to ap-southeast-2) |


**Note:** If calling this workflow from an external GitHub organisation, you will need to pass the AWS_SECRET_ACCESS_KEY explicitly (see example below).

#### Example Usage

```yaml
jobs:
  deploy-serverless:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      environment: development
      debug: true
```

```yaml
name: 🚀 Deploy

on:
  push:
    branches:
      - staging
      - production

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      environment: ${{ github.ref_name == 'production' && 'Production' || 'Staging' }}
      package-manager: npm
```

```yaml
name: 🚀 Deploy

on:
  push:
    branches:
      - staging
      - production

jobs:
  deploy:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      environment: ${{ github.ref_name == 'production' && 'Production' || 'Staging' }}
      package-manager: npm
    secrets:
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```