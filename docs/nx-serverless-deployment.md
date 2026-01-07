# Nx Serverless Deployment

#### **Inputs**
| Name                 | Required | Type    | Default         | Description                                |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key                             |
| cfn-role             | ✅       | string  |                 | AWS CFN Role to assume                     |
| aws-profile          | ✅       | string  |                 | AWS Profile                                |
| aws-region           | ❌       | string  | ap-southeast-2  | AWS Region to deploy to                    |
| stage                | ✅       | string  |                 | Stage to deploy to                         |
| environment          | ✅       | string  |                 | The GitHub environment to run in           |
| command              | ❌       | string  | build           | Command to run during the deploy step      |
| package-manager      | ❌       | string  | yarn            | Node package manager to use                |
| build-command        | ❌       | string  | build           | Command to override the build command      |
| debug                | ❌       | boolean | false           | If verbose logging should be enabled       |

#### **Secrets**
| Name | Required | Description |
|------|----------|-------------|
| aws-secret-access-key | ✅ | AWS secret access key |

#### Example Usage

```yaml
jobs:
  deploy-serverless:
    uses: aligent/workflows/.github/workflows/nx-serverless-deployment.yml@main
    with:
      aws-profile: my-profile
      stage: dev
      environment: development
      debug: true
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```