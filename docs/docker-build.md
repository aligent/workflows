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
| platforms         | ❌       | string  |                                                      | Target platforms (e.g., `linux/amd64,linux/arm64`) |
| push              | ❌       | boolean | `true`                                               | Push image to registry                           |
| tags              | ❌       | string  | `type=raw,value=latest,enable={{is_default_branch}}`<br>`type=sha,prefix=` | Custom tags for docker/metadata-action |
| no-cache          | ❌       | boolean | `false`                                              | Disable build cache                              |
| cache-from        | ❌       | string  | `type=gha`                                           | Cache source                                     |
| cache-to          | ❌       | string  | `type=gha,mode=max`                                  | Cache destination                                |
| provenance        | ❌       | boolean | `false`                                              | Generate provenance attestation                  |
| timeout-minutes   | ❌       | number  | `60`                                                 | Job timeout in minutes                           |
| dockerhub-username| ✅       | string  |                                                      | Docker Hub username (from vars)                  |

#### **Secrets**
| Name              | Required | Description                                          |
|-------------------|----------|------------------------------------------------------|
| dockerhub-token   | ✅       | Docker Hub access token                              |
| build-secrets     | ❌       | Docker BuildKit secrets (newline-separated KEY=value)|
| build-args-secrets| ❌       | Secret build arguments appended to build-args        |

#### **Features**

- **Split build and push**: Build and push are separate steps with a fresh Docker Hub login before push, preventing token timeout for long-running builds.
- **Multi-platform support**: Optional QEMU setup for cross-platform builds.
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

#### Example with Multi-Platform Build

```yaml
jobs:
  build-and-push:
    uses: aligent/workflows/.github/workflows/docker-build.yml@main
    with:
      image-name: aligent/my-app
      dockerhub-username: ${{ vars.DOCKERHUB_USERNAME }}
      platforms: linux/amd64,linux/arm64
    secrets:
      dockerhub-token: ${{ secrets.DOCKERHUB_TOKEN }}
```
