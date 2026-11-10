# Docker Build and Push

Build and push Docker images to Docker Hub with support for multi-platform builds, caching, and BuildKit secrets.

#### **Inputs**
| Name              | Required | Type    | Default                                              | Description                                      |
|-------------------|----------|---------|------------------------------------------------------|--------------------------------------------------|
| image-name        | ✅       | string  |                                                      | Docker image name (e.g., `aligent/my-app`)       |
| registry          | ❌       | string  | `docker.io`                                          | Docker registry                                  |
| context           | ❌       | string  | `.`                                                  | Build context path                               |
| dockerfile        | ❌       | string  | `Dockerfile`                                         | Path to Dockerfile                               |
| build-args        | ❌       | string  |                                                      | Build arguments (newline-separated KEY=value)    |
| push              | ❌       | boolean | `true`                                               | Push image to registry                           |
| tags              | ❌       | string  | `type=raw,value=latest,enable={{is_default_branch}}`<br>`type=sha,prefix=` | Custom tags for docker/metadata-action |
| no-cache          | ❌       | boolean | `false`                                              | Disable build cache                              |
| cache-from        | ❌       | string  | `type=gha`                                           | Cache source                                     |
| cache-to          | ❌       | string  | `type=gha,mode=max`                                  | Cache destination                                |
| provenance        | ❌       | boolean | `false`                                              | Generate provenance attestation                  |
| timeout-minutes   | ❌       | number  | `60`                                                 | Job timeout in minutes                           |
| dockerhub-username| ❌       | string  |                                                      | Docker Hub username (from vars). Required when `push: true` (default). |
| runs-on           | ❌       | string  | `ubuntu-latest`                                      | Runner to use (e.g. `ubuntu-24.04-arm` for native ARM64 builds) |
| target            | ❌       | string  |                                                      | Dockerfile stage to build. Defaults to the last stage |

#### **Secrets**
| Name              | Required | Description                                          |
|-------------------|----------|------------------------------------------------------|
| dockerhub-token   | ❌       | Docker Hub access token. Required when `push: true` (default). |
| build-secrets     | ❌       | Docker BuildKit secrets (newline-separated KEY=value)|
| build-args-secrets| ❌       | Secret build arguments appended to build-args        |

#### **Features**

- **Split build and push**: Build and push are separate steps with a fresh Docker Hub login before push, preventing token timeout for long-running builds.
- **Selectable architecture**: `runs-on` picks the build architecture — `ubuntu-latest` for amd64, `ubuntu-24.04-arm` for arm64. The build is always native, never emulated.
- **GitHub Actions cache**: Uses `type=gha` caching by default for faster builds.
- **BuildKit secrets**: Securely pass secrets during build without exposing them in logs.
- **Flexible tagging**: Uses docker/metadata-action for automatic tag generation.

#### Example Usage

```yaml
name: Build and Push Docker Image

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2am UTC
  workflow_dispatch:

jobs:
  build-and-push:
    uses: aligent/workflows/.github/workflows/docker-build.yml@main
    with:
      image-name: aligent/my-app
      dockerhub-username: ${{ vars.DOCKERHUB_USERNAME }}
      build-args: |
        BUILD_ENV=production
    secrets:
      dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
```

#### Example with BuildKit Secrets

For builds requiring sensitive data (e.g., API keys during build):

```yaml
jobs:
  build-and-push:
    uses: aligent/workflows/.github/workflows/docker-build.yml@main
    with:
      image-name: aligent/my-app
      dockerhub-username: ${{ vars.DOCKERHUB_USERNAME }}
      timeout-minutes: 360
      build-args: |
        UPDATE_DB=true
    secrets:
      dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
      build-secrets: |
        NVD_API_KEY=${{ secrets.NVD_API_KEY }}
```

In your Dockerfile, access the secret:

```dockerfile
RUN --mount=type=secret,id=NVD_API_KEY,mode=0444 \
    SECRET_VALUE=$(cat /run/secrets/NVD_API_KEY) && \
    # use SECRET_VALUE...
```

#### Choosing the build architecture

Images are single-architecture. The build always runs natively on the runner's
own architecture, so `runs-on` is what selects it — `ubuntu-latest` for amd64
(the default), `ubuntu-24.04-arm` for arm64.

```yaml
jobs:
  build:
    uses: aligent/workflows/.github/workflows/docker-build.yml@main
    with:
      image-name: aligent/my-app
      dockerhub-username: ${{ vars.DOCKERHUB_USERNAME }}
      runs-on: ubuntu-24.04-arm
    secrets:
      dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
```

The published image is arm64-only: an amd64 host pulling this tag gets a
manifest with no matching platform and the pull fails. Only do this where every
consumer is known to be on the one architecture.

`ubuntu-24.04-arm` is free for public repositories; for private repositories it
is a paid larger-runner SKU that must be enabled for the organisation.

See `aligent/magento-local` for a worked example that also fans out over
multiple Dockerfile stages via `target`.
