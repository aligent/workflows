# S3 Deployment

#### **Inputs**
| Name                  | Required | Type    | Default         | Description                               |
|--------------------- |----------|---------|-----------------|--------------------------------------------|
| aws-region           | ❌       | string  | ap-southeast-2  | AWS region                                 |
| s3-bucket            | ✅       | string  |                 | Name of the S3 bucket                      |
| s3-path              | ❌       | string  |                 | Path in the S3 bucket                      |
| local-path           | ✅       | string  |                 | Path to deploy                             |
| delete-flag          | ❌       | boolean | true            | Enable --delete flag                       |
| cache-control        | ❌       | string  |                 | Cache control headers                      |
| extra-args           | ❌       | string  |                 | Additional AWS CLI args                    |
| aws-access-key-id    | ✅       | string  |                 | AWS Access Key ID                          |

#### **Secrets**
| Name                  | Required | Description                               |
|--------------------- |----------|--------------------------------------------|
| aws-secret-access-key| ✅       | AWS Secret Access Key                      |

#### **Backport Configuration (Optional)**

Enable automatic PR creation to backport changes to a staging branch after successful deployments.

| Name | Type | Description |
|------|------|-------------|
| `BACKPORT_TO_STAGING` | Variable | Set to `true` to enable backporting |
| `BACKPORT_TARGET_BRANCH` | Variable | Target branch for backport (defaults to `staging`) |

**Note:** Backporting only occurs when deploying from `production`, `main`, or `master` branches. Deployments from other branches are skipped.

#### Example Usage

```yaml
jobs:
  deploy-to-s3:
    uses: aligent/workflows/.github/workflows/s3-deploy.yml@main
    with:
      s3-bucket: my-bucket
      local-path: ./dist
      s3-path: /public
      cache-control: "max-age=3600"
      aws-access-key-id: ${{ vars.AWS_ACCESS_KEY_ID }}
    secrets:
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```