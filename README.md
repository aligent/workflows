# Aligent GitHub Actions

A collection of GitHub action workflows. Built using the [reusable workflows](https://docs.github.com/en/actions/sharing-automations/reusing-workflows) guide from GitHub.

## Actions

### S3 Deploy

#### **Inputs**
| Name          | Required | Type    | Default            | Description                 |
|--------------|----------|---------|--------------------|-----------------------------|
| aws-region   | ❌       | string  | ap-southeast-2    | AWS region                 |
| s3-bucket    | ✅       | string  | -                  | Name of the S3 bucket      |
| s3-path      | ❌       | string  | -                  | Path in the S3 bucket      |
| local-path   | ✅       | string  | ""                 | Path to deploy             |
| delete-flag  | ❌       | boolean | true               | Enable `--delete` flag     |
| cache-control| ❌       | string  | -                  | Cache control headers      |
| extra-args   | ❌       | string  | -                  | Additional AWS CLI args    |

#### **Secrets**
| Name                  | Required | Description                     |
|-----------------------|----------|---------------------------------|
| aws-access-key-id     | ✅       | AWS Access Key ID              |
| aws-secret-access-key | ✅       | AWS Secret Access Key          |

#### Example Usage

```yaml
uses: aligent/actions/.github/actions/s3-deploy@latest
with:
    s3-bucket: "bucket-name"
secrets:
    aws-access-key-id: ${{ secrets.aws-access-key-id }}
    aws-secret-access-key: ${{ secrets.aws-secret-access-key }}
```
