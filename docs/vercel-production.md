# Vercel Production Deployment

Deploys a production build to Vercel. Intended to be called from a `push` (or
`workflow_dispatch`) triggered workflow.

#### **Inputs**
| Name               | Required | Type   | Default    | Description                            |
|--------------------|----------|--------|------------|----------------------------------------|
| vercel-org-id      | ✅       | string |            | Vercel organisation ID                 |
| vercel-project-id  | ✅       | string |            | Vercel project ID                      |
| vercel-target      | ❌       | string |            | Vercel environment target to deploy to |
| working-directory  | ❌       | string | .          | Directory to run the Vercel deploy from |
| environment-name   | ❌       | string | Production | GitHub Environment to deploy to        |

#### **Secrets**
| Name          | Required | Description              |
|---------------|----------|--------------------------|
| vercel-token  | ✅       | Vercel deployment token  |

#### Concurrency

Runs are grouped by ref, `vercel-project-id` **and** `vercel-target`, with
`cancel-in-progress: false`. Deploys for the same project and target queue in order,
while deploys for different projects or targets run in parallel.

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

#### Deploying more than one Vercel project

Call the workflow once per project. Give each call a distinct
`environment-name`, otherwise every job writes its deployment status and URL to
the same GitHub Environment and the last one to finish wins.

```yaml
jobs:
  deploy-storefront-production:
    uses: aligent/workflows/.github/workflows/vercel-production.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
      environment-name: Production
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}

  deploy-admin-production:
    uses: aligent/workflows/.github/workflows/vercel-production.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_ADMIN_PROJECT_ID }}
      environment-name: Production - admin
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
```
