# Vercel Preview Performance

Measures Core Web Vitals against an already-deployed Vercel preview with
[Lighthouse CI](https://github.com/treosh/lighthouse-ci-action) and posts the
median results as a pull request comment.

Desktop and mobile run concurrently as a matrix, each against its own budgets.

The caller decides what to measure and when: pair it with
[Vercel Preview Deployment](vercel-preview.md) via `needs`, and call it again
from a push-to-default-branch workflow with `baseline-mode: record` to keep the
baseline current.

#### **Inputs**
| Name                   | Required | Type   | Default                                       | Description                                    |
|------------------------|----------|--------|-----------------------------------------------|------------------------------------------------|
| deployment-url         | ✅       | string |                                               | Deployment to measure. May still be building.  |
| vercel-org-id          | ✅       | string |                                               | Vercel organisation ID owning the deployment   |
| measured-paths         | ✅       | string |                                               | Paths to measure, one per line                 |
| baseline-mode          | ❌       | string | none                                          | `compare`, `record` or `none`                  |
| baseline-key           | ❌       | string | default                                       | Names the baseline; give each measured deployment its own |
| lighthouse-config-path | ❌       | string | .github/lighthouse/lighthouserc.{form-factor}.json | Lighthouse CI config in the caller repo   |
| regression-threshold   | ❌       | number | 20                                            | Percent a metric may worsen before flagging    |
| node-version-file      | ❌       | string | .nvmrc                                        | File to read the Node version from             |

#### **Secrets**
| Name                            | Required | Description                                              |
|---------------------------------|----------|----------------------------------------------------------|
| vercel-token                    | ✅       | Used to wait for the deployment to be ready              |
| vercel-automation-bypass-secret | ❌       | Protection Bypass for Automation, if protection is on    |

### How it works

1. Waits for the deployment to finish building, so the caller can deploy with
   `--no-wait` and hand over the URL immediately.
2. Warms each measured path. The first request to a cold preview pays
   serverless cold start and any on-demand page generation, which would
   otherwise be measured as page latency.
3. Runs Lighthouse against every path, for desktop and mobile, and reports the
   median of each metric.

### Baseline comparison

Absolute budgets cannot tell "this pull request made things worse" from "this
runner was busy". A regression from 1.2s to 3.5s passes a 4s budget silently.
Comparing against the default branch isolates what the change actually did.

Recording must run on the **default branch**: a pull request can read a cache
the default branch wrote, but not the reverse. So the two modes live in two
caller workflows — `compare` on `pull_request`, `record` on push to the default
branch.

A repository measuring more than one deployment must give each its own
`baseline-key`. Baselines are cached per key and form factor, so without it two
deployments overwrite each other and pull requests compare against whichever
recorded last. The key must match between the recording and comparing callers.

#### Keeping the baseline alive

GitHub evicts a cache that has not been read for 7 days. Because the baseline
is only rewritten on a merge, a quiet fortnight drops it silently and pull
requests report no baseline until the next merge.

`vercel-performance-keepalive.yml` restores the baselines and does nothing
else, which resets that clock for seconds of runner time. It knows which form
factors are measured, so the caller supplies only its baseline keys:

```yaml
on:
  schedule:
    # Every third day, against a 7 day expiry. Scheduled runs are delayed under
    # load and can be dropped, so this leaves slack rather than sitting at the
    # boundary.
    - cron: '0 17 */3 * *'
  workflow_dispatch:

jobs:
  keep-baselines-alive:
    uses: aligent/workflows/.github/workflows/vercel-performance-keepalive.yml@main
    with:
      baseline-keys: |
        paas
        accs
```

A missing baseline is reported as a warning rather than a failure: pull
requests degrade gracefully without one, and the next merge records it again.

### Example Usage

Measuring a pull request, comparing against the baseline:

```yaml
on:
  pull_request:

jobs:
  deploy-preview:
    uses: aligent/workflows/.github/workflows/vercel-preview.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}

  performance:
    needs: deploy-preview
    uses: aligent/workflows/.github/workflows/vercel-performance.yml@main
    with:
      deployment-url: ${{ needs.deploy-preview.outputs.url }}
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      baseline-mode: compare
      # Names this baseline. Required only when measuring more than one
      # deployment, but explicit here to show the pairing.
      baseline-key: paas
      measured-paths: |
        /
        /category/example
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
      vercel-automation-bypass-secret: ${{ secrets.VERCEL_AUTOMATION_BYPASS_SECRET }}
```

Recording the baseline after a merge. The measured paths must match those above,
or pull requests will have nothing to compare against:

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy-preview:
    uses: aligent/workflows/.github/workflows/vercel-preview.yml@main
    with:
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      vercel-project-id: ${{ vars.VERCEL_PROJECT_ID }}
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}

  record-baseline:
    needs: deploy-preview
    uses: aligent/workflows/.github/workflows/vercel-performance.yml@main
    with:
      deployment-url: ${{ needs.deploy-preview.outputs.url }}
      vercel-org-id: ${{ vars.VERCEL_ORG_ID }}
      baseline-mode: record
      # Names this baseline. Required only when measuring more than one
      # deployment, but explicit here to show the pairing.
      baseline-key: paas
      measured-paths: |
        /
        /category/example
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
      vercel-automation-bypass-secret: ${{ secrets.VERCEL_AUTOMATION_BYPASS_SECRET }}
```

The baseline is deliberately a **preview built from the default branch**, not a
production deployment. Production is warm, CDN-cached, and often points at
different data and environment variables, so a preview measured against it would
show deltas caused by the environment rather than by the change.

### Lighthouse config

The caller supplies one config per form factor. `{form-factor}` in the path is
replaced with `desktop` or `mobile`:

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

The mobile config sets `"formFactor": "mobile"` instead of `"preset": "desktop"`,
which applies mobile emulation and a 4x CPU slowdown. Its budgets should be
roughly 1.5x desktop as a result; CLS is unchanged, as layout shift is not
throttling-dependent.

Three things in that config are worth calling out:

- **`aggregationMethod: median`** — Lighthouse CI defaults to `optimistic`,
  which takes the *best* run and so discards the variance that multiple runs
  exist to smooth out. Set this explicitly.
- **`numberOfRuns: 3`** — a single run against a cold preview is not a usable
  signal. An odd count means the median is a value that was actually measured.
- **`warn` rather than `error`** — the job reports breaches without failing, so
  a noisy preview cannot block a merge. Switch to `error` once you have enough
  history to trust the thresholds.

### Reading the results

Preview deployments are cold and run on shared CI runners, so treat the numbers
as a smoke signal for large regressions rather than a benchmark. Keep budgets
loose: scoring a preview against production-grade thresholds flags nearly every
pull request, and a check that cries wolf gets ignored.

### Deployment Protection

If the Vercel project has [Deployment
Protection](https://vercel.com/docs/deployment-protection) enabled, preview URLs
require a Vercel login. Automated requests receive an authentication page rather
than the site, so Lighthouse would score the login screen instead of the page
under test.

To allow the check through, generate a [Protection Bypass for
Automation](https://vercel.com/docs/deployment-protection/methods-to-bypass-deployment-protection/protection-bypass-automation)
secret in the Vercel project's Deployment Protection settings, add it to the
calling repository as a secret, and pass it as
`vercel-automation-bypass-secret`. The workflow sends it as the
`x-vercel-protection-bypass` header on both the warm-up requests and the
Lighthouse runs.

Generating the secret requires at least the **member** team role, or the
**Project Administrator** role on the project. Note that regenerating or
deleting a secret invalidates it for existing deployments, which then need to
be redeployed.

The secret is optional and is omitted from requests entirely when unset, which
is correct for a project without Deployment Protection. If protection *is*
enabled and the secret is missing, the warm-up step fails with a non-200 status
rather than reporting misleading scores.

To check whether a project needs it, open a preview URL in a private browser
window: a login prompt means protection is enabled.

> Vercel also exposes this value to the running deployment as the
> `VERCEL_AUTOMATION_BYPASS_SECRET` system environment variable, but that is not
> usable here — the workflow needs the secret *before* it can reach the
> deployment, so it must come from repository secrets.
