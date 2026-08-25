# Vercel Preview Deployment

Deploys a preview build to Vercel and posts (or updates) a single comment on the
pull request with the preview and inspect URLs. Intended to be called from a
`pull_request` triggered workflow.

#### **Inputs**
| Name                   | Required | Type    | Default                                  | Description                             |
|------------------------|----------|---------|------------------------------------------|-----------------------------------------|
| vercel-org-id          | ✅       | string  |                                          | Vercel organisation ID                  |
| vercel-project-id      | ✅       | string  |                                          | Vercel project ID                       |
| working-directory      | ❌       | string  | .                                        | Directory to run the Vercel deploy from |
| environment-name       | ❌       | string  | Preview                                  | GitHub Environment to deploy to         |
| performance-check      | ❌       | boolean | false                                    | Run a Lighthouse check against the preview |
| measured-paths         | ❌       | string  |                                          | Paths to measure, one per line          |
| lighthouse-config-path | ❌       | string  | .github/lighthouse/lighthouserc.json     | Lighthouse CI config in the caller repo |
| node-version-file      | ❌       | string  | .nvmrc                                   | Node version file for the check         |

#### **Secrets**
| Name                            | Required | Description                                          |
|---------------------------------|----------|------------------------------------------------------|
| vercel-token                    | ✅       | Vercel deployment token                              |
| vercel-automation-bypass-secret | ❌       | Protection Bypass for Automation, for the perf check |

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

## Performance Check

Optionally measures Core Web Vitals against the preview deployment with
[Lighthouse CI](https://github.com/treosh/lighthouse-ci-action) and posts the
median results as a pull request comment.

The check is **off by default**. It runs only when `performance-check` is true
*and* `measured-paths` is non-empty, so existing callers are unaffected.

### How it works

1. Waits for the preview deployment to finish building (the deploy step uses
   `--no-wait`, so the deploy job itself returns as soon as it has a URL).
2. Warms each measured path. The first request to a cold preview pays
   serverless cold start and any on-demand page generation, which would
   otherwise be measured as page latency.
3. Runs Lighthouse against every path and comments the median of each metric.

### Reading the results

Preview deployments are cold and run on shared CI runners, so treat the numbers
as a smoke signal for large regressions rather than a benchmark. Two things
follow from that:

- **Use several runs and aggregate on the median.** A single run on a cold
  preview is not a usable signal.
- **Keep budgets loose.** Scoring a preview against production-grade
  thresholds flags nearly every pull request, and a check that cries wolf gets
  ignored.

### Example Usage

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
      performance-check: true
      # One path per line. Paths may contain query strings.
      measured-paths: |
        /
        /women/tops-women/jackets-women.html
        /stellar-solar-jacket.html?categoryPath=jackets-women
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
      # Only needed when Deployment Protection is enabled on the project.
      vercel-automation-bypass-secret: ${{ secrets.VERCEL_AUTOMATION_BYPASS_SECRET }}
```

The caller supplies the Lighthouse CI config, by default at
`.github/lighthouse/lighthouserc.json`:

```json
{
    "ci": {
        "collect": {
            "numberOfRuns": 3,
            "settings": {
                "preset": "desktop",
                "onlyCategories": ["performance"],
                "maxWaitForLoad": 60000,
                "chromeFlags": "--no-sandbox --disable-dev-shm-usage"
            }
        },
        "assert": {
            "aggregationMethod": "median",
            "assertions": {
                "categories:performance": ["warn", { "minScore": 0.5 }],
                "largest-contentful-paint": ["warn", { "maxNumericValue": 4000 }],
                "total-blocking-time": ["warn", { "maxNumericValue": 600 }],
                "cumulative-layout-shift": ["warn", { "maxNumericValue": 0.25 }],
                "first-contentful-paint": ["warn", { "maxNumericValue": 3000 }],
                "speed-index": ["warn", { "maxNumericValue": 5800 }]
            }
        }
    }
}
```

Two things in that config are worth calling out:

- **`aggregationMethod: median`** — Lighthouse CI defaults to `optimistic`,
  which takes the *best* run and so discards the variance that multiple runs
  exist to smooth out. Set this explicitly.
- **`warn` rather than `error`** — the job reports breaches without failing, so
  a noisy preview cannot block a merge. Switch to `error` once you have enough
  history to trust the thresholds.
