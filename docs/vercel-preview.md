# Vercel Preview Deployment

Deploys a preview build to Vercel and posts (or updates) a single comment on the
pull request with the preview and inspect URLs. Intended to be called from a
`pull_request` triggered workflow.

#### **Inputs**
| Name               | Required | Type   | Default  | Description                             |
|--------------------|----------|--------|----------|-----------------------------------------|
| vercel-org-id      | ✅       | string |          | Vercel organisation ID                  |
| vercel-project-id  | ✅       | string |          | Vercel project ID                       |
| working-directory  | ❌       | string | .        | Directory to run the Vercel deploy from |
| environment-name   | ❌       | string | Preview  | GitHub Environment to deploy to. Also used as the heading of the pull request comment |

#### **Outputs**
| Name | Description                                                             |
|------|-------------------------------------------------------------------------|
| url  | The preview deployment URL. Still building when the job ends, as the deploy uses `--no-wait`. |

#### **Secrets**
| Name          | Required | Description              |
|---------------|----------|--------------------------|
| vercel-token  | ✅       | Vercel deployment token  |

#### Concurrency

Runs are grouped by pull request **and** `vercel-project-id`, with
`cancel-in-progress: true`. A new commit supersedes the in-flight preview for
that project, while previews for other projects are left alone.

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

#### Deploying more than one Vercel project

Call the workflow once per project. Give each call a distinct
`environment-name`, otherwise every job writes its deployment status and URL to
the same GitHub Environment and the last one to finish wins.

```yaml
jobs:
  deploy-storefront-preview:
    uses: aligent/workflows/.github/workflows/vercel-preview.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
      environment-name: Preview
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}

  deploy-admin-preview:
    uses: aligent/workflows/.github/workflows/vercel-preview.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_ADMIN_PROJECT_ID }}
      environment-name: Preview - admin
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
```

Each project gets its own PR comment, keyed on the project ID.

To measure the performance of the resulting preview, pair this with
[Vercel Preview Performance](vercel-performance.md), which takes the `url`
output above.
