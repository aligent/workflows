# Uptime Kuma Pause/Resume

Pauses and resumes Uptime Kuma monitors during deployments to prevent false downtime alerts. Connects to Uptime Kuma via Socket.IO, authenticates, and calls `pauseMonitor` or `resumeMonitor` for each specified monitor ID.

Designed to be called twice in a deployment workflow: once before deploying (pause) and once after (resume). The resume job should always run, even if the deployment fails, so monitors are never left paused.

#### **Inputs**

| Name | Required | Type | Default | Description |
|------|----------|------|---------|-------------|
| action | Yes | string | | `pause` or `resume` |
| kuma-url | Yes | string | | Uptime Kuma base URL (e.g., `https://status.aligent.cloud`). Recommended: store in `vars.KUMA_URL`. |
| monitor-ids | Yes | string | | Comma-separated monitor IDs (e.g., `12,15,18`). Recommended: store in `vars.KUMA_MONITOR_IDS`. See [Finding Monitor IDs](#finding-monitor-ids). |
| timeout | No | number | 30 | Seconds to wait for Socket.IO connection and operations |
| debug | No | boolean | false | Enable verbose logging |

#### **Secrets**

| Name | Required | Description |
|------|----------|-------------|
| KUMA_USERNAME | Yes | Uptime Kuma login username |
| KUMA_PASSWORD | Yes | Uptime Kuma login password |

#### How It Works

1. Checks out the `scripts/uptime-kuma.mjs` script from the workflows repo using sparse checkout.
2. Sets up Node.js and installs `socket.io-client`.
3. Connects to Uptime Kuma via Socket.IO and authenticates with username/password.
4. Calls `pauseMonitor` or `resumeMonitor` for each monitor ID.
5. Reports which monitors were successfully paused/resumed and which failed.
6. If any monitor fails, the step exits with a non-zero code after attempting all monitors.

#### Finding Monitor IDs

You need the numeric monitor IDs from Uptime Kuma to configure `KUMA_MONITOR_IDS`.

**From the Uptime Kuma UI:**

1. Log in to your Uptime Kuma dashboard.
2. Click on the monitor you want to target.
3. The monitor ID is in the URL: `https://status.example.com/dashboard/<monitor-id>`.
4. Repeat for each monitor and join them with commas (e.g., `12,15,18`).

**From the browser developer console:**

1. Log in to your Uptime Kuma dashboard.
2. Open the browser developer console (F12 > Console).
3. Run the following to list all monitors with their IDs and names:
   ```javascript
   Object.values($root.monitorList).forEach(m => console.log(`${m.id} - ${m.name}`));
   ```

#### Example Usage

**Recommended setup:** Store `KUMA_URL` and `KUMA_MONITOR_IDS` as GitHub Actions repository variables (Settings > Secrets and variables > Actions > Variables), and `KUMA_USERNAME`/`KUMA_PASSWORD` as secrets.

**Wrap a deployment with pause/resume:**
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  pause-monitoring:
    uses: aligent/workflows/.github/workflows/uptime-kuma.yml@main
    with:
      action: pause
      kuma-url: ${{ vars.KUMA_URL }}
      monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
    secrets:
      KUMA_USERNAME: ${{ secrets.KUMA_USERNAME }}
      KUMA_PASSWORD: ${{ secrets.KUMA_PASSWORD }}

  deploy:
    needs: [pause-monitoring]
    runs-on: ubuntu-latest
    steps:
      - run: echo "deploying..."

  resume-monitoring:
    needs: [deploy]
    if: always()
    uses: aligent/workflows/.github/workflows/uptime-kuma.yml@main
    with:
      action: resume
      kuma-url: ${{ vars.KUMA_URL }}
      monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
    secrets:
      KUMA_USERNAME: ${{ secrets.KUMA_USERNAME }}
      KUMA_PASSWORD: ${{ secrets.KUMA_PASSWORD }}
```

**With verbose logging:**
```yaml
  pause-monitoring:
    uses: aligent/workflows/.github/workflows/uptime-kuma.yml@main
    with:
      action: pause
      kuma-url: ${{ vars.KUMA_URL }}
      monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
      debug: true
    secrets:
      KUMA_USERNAME: ${{ secrets.KUMA_USERNAME }}
      KUMA_PASSWORD: ${{ secrets.KUMA_PASSWORD }}
```

#### Important Notes

- The resume job must use `if: always()` so monitors are resumed even if the deployment fails.
- If Uptime Kuma is unreachable, the pause step will fail. Consider using `continue-on-error: true` on the pause job if you don't want a monitoring outage to block deployments.
- Monitor IDs are stable and don't change unless the monitor is deleted and recreated. If you add or remove monitors, update the `KUMA_MONITOR_IDS` variable.
- The script attempts all monitors even if some fail, so a single invalid ID won't prevent the rest from being paused/resumed.
