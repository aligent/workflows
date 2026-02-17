# Uptime Kuma Pause/Resume

Composite action that pauses and resumes Uptime Kuma monitors during deployments to prevent false downtime alerts. Connects to Uptime Kuma via Socket.IO, authenticates, and calls `pauseMonitor` or `resumeMonitor` for each specified monitor ID.

Designed to be used as steps within a deployment job: once before deploying (pause) and once after (resume). The resume step should use `if: always()` so monitors are never left paused if the deployment fails.

Because this is a composite action (not a reusable workflow), it runs within the caller's existing job and does not consume additional build minutes.

#### **Inputs**

| Name | Required | Default | Description |
|------|----------|---------|-------------|
| action | Yes | | `pause` or `resume` |
| kuma-url | Yes | | Uptime Kuma base URL (e.g., `https://status.aligent.cloud`). Recommended: store in `vars.KUMA_URL`. |
| monitor-ids | Yes | | Comma-separated monitor IDs (e.g., `12,15,18`). Recommended: store in `vars.KUMA_MONITOR_IDS`. See [Finding Monitor IDs](#finding-monitor-ids). |
| kuma-username | Yes | | Uptime Kuma login username. Pass from `${{ secrets.KUMA_USERNAME }}`. |
| kuma-password | Yes | | Uptime Kuma login password. Pass from `${{ secrets.KUMA_PASSWORD }}`. |
| timeout | No | 30 | Seconds to wait for Socket.IO connection and operations |
| debug | No | false | Enable verbose logging |

#### How It Works

1. Installs `socket.io-client` in the action directory.
2. Runs the `uptime-kuma.js` script which connects to Uptime Kuma via Socket.IO.
3. Authenticates with the provided username and password.
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

**As steps within a deployment job (recommended, no extra build minutes):**
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: aligent/workflows/.github/actions/uptime-kuma@main
        with:
          action: pause
          kuma-url: ${{ vars.KUMA_URL }}
          monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
          kuma-username: ${{ secrets.KUMA_USERNAME }}
          kuma-password: ${{ secrets.KUMA_PASSWORD }}

      - run: echo "deploying..."

      - uses: aligent/workflows/.github/actions/uptime-kuma@main
        if: always()
        with:
          action: resume
          kuma-url: ${{ vars.KUMA_URL }}
          monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
          kuma-username: ${{ secrets.KUMA_USERNAME }}
          kuma-password: ${{ secrets.KUMA_PASSWORD }}
```

**As separate jobs (when the deployment is a reusable workflow call):**
```yaml
jobs:
  pause-monitoring:
    runs-on: ubuntu-latest
    steps:
      - uses: aligent/workflows/.github/actions/uptime-kuma@main
        with:
          action: pause
          kuma-url: ${{ vars.KUMA_URL }}
          monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
          kuma-username: ${{ secrets.KUMA_USERNAME }}
          kuma-password: ${{ secrets.KUMA_PASSWORD }}

  deploy:
    needs: [pause-monitoring]
    uses: aligent/workflows/.github/workflows/some-deploy.yml@main

  resume-monitoring:
    needs: [deploy]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: aligent/workflows/.github/actions/uptime-kuma@main
        with:
          action: resume
          kuma-url: ${{ vars.KUMA_URL }}
          monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
          kuma-username: ${{ secrets.KUMA_USERNAME }}
          kuma-password: ${{ secrets.KUMA_PASSWORD }}
```

**With verbose logging:**
```yaml
      - uses: aligent/workflows/.github/actions/uptime-kuma@main
        with:
          action: pause
          kuma-url: ${{ vars.KUMA_URL }}
          monitor-ids: ${{ vars.KUMA_MONITOR_IDS }}
          kuma-username: ${{ secrets.KUMA_USERNAME }}
          kuma-password: ${{ secrets.KUMA_PASSWORD }}
          debug: "true"
```

#### Important Notes

- The resume step must use `if: always()` so monitors are resumed even if the deployment fails.
- If Uptime Kuma is unreachable, the pause step will fail. Consider using `continue-on-error: true` on the step if you don't want a monitoring outage to block deployments.
- Monitor IDs are stable and don't change unless the monitor is deleted and recreated. If you add or remove monitors, update the `KUMA_MONITOR_IDS` variable.
- The script attempts all monitors even if some fail, so a single invalid ID won't prevent the rest from being paused/resumed.
- Credentials are passed as inputs rather than secrets because composite actions cannot access the `secrets` context directly. GitHub Actions still masks them in logs as long as the caller passes `${{ secrets.X }}`.
