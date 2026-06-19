# Vercel Preview Deployment

Deploys a preview build to Vercel and posts (or updates) a single comment on the
pull request with the preview and inspect URLs. Intended to be called from a
`pull_request` triggered workflow.

#### **Inputs**
| Name               | Required | Type   | Default  | Description                            |
|--------------------|----------|--------|----------|----------------------------------------|
| vercel-org-id      | ✅       | string |          | Vercel organisation ID                 |
| vercel-project-id  | ✅       | string |          | Vercel project ID                      |
| working-directory  | ❌       | string | .        | Directory to run the Vercel deploy from |
| environment-name   | ❌       | string | Preview  | GitHub Environment to deploy to        |

#### **Secrets**
| Name          | Required | Description              |
|---------------|----------|--------------------------|
| vercel-token  | ✅       | Vercel deployment token  |

#### Example Usage

```yaml
on:
  pull_request:
    branches:
      - main

jobs:
  deploy-preview:
    uses: aligent/workflows/.github/workflows/vercel-preview.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
```
