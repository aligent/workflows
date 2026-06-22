# Vercel Production Deployment

Deploys a production build to Vercel. Intended to be called from a `push` (or
`workflow_dispatch`) triggered workflow.

#### **Inputs**
| Name               | Required | Type   | Default    | Description                            |
|--------------------|----------|--------|------------|----------------------------------------|
| vercel-org-id      | ✅       | string |            | Vercel organisation ID                 |
| vercel-project-id  | ✅       | string |            | Vercel project ID                      |
| working-directory  | ❌       | string | .          | Directory to run the Vercel deploy from |
| environment-name   | ❌       | string | Production | GitHub Environment to deploy to        |

#### **Secrets**
| Name          | Required | Description              |
|---------------|----------|--------------------------|
| vercel-token  | ✅       | Vercel deployment token  |

#### Example Usage

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy-production:
    uses: aligent/workflows/.github/workflows/vercel-production.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
```
