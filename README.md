# fineract-site

Apache Fineract website source repository for https://fineract.apache.org.

## Prerequisites

- Git
- Docker

## Source Of Truth

- Hugo source is in `site-src/`.
- Generated output is in `.build/site`.
- Static passthrough is mounted from:
  - `docs/` -> `/docs/`
  - `css/` -> `/css/`
  - `js/` -> `/js/`
  - `images/` -> `/images/`
  - `font/` -> `/font/`
  - `.htaccess` -> `/.htaccess`
  - `doap_Fineract.rdf` -> `/doap_Fineract.rdf`

Do not edit generated output directly. Edit files under `site-src/` and mounted static sources instead.

## Local Build and Checks (Docker)

1. Build the site tool image:

```bash
docker build -t fineract-site .
```

2. Build site and run checks (internal links + htmlhint + axe):

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site build
```

3. Serve locally with watch mode:

```bash
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -p 1313:1313 \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site serve
```

4. Optional: run checks only (without rebuilding):

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site check
```

Windows PowerShell equivalent (no UID/GID mapping):

```powershell
docker build -t fineract-site .
docker run --rm -v "${PWD}:/src" -w /src/site-src fineract-site build
docker run --rm -it -p 1313:1313 -v "${PWD}:/src" -w /src/site-src fineract-site serve
```

If Docker creates root-owned artifacts on Linux, fix ownership with:

```bash
sudo chown -R "$(id -u):$(id -g)" .build site-src
```

## CI/CD

- PR validation workflow: `.github/workflows/site-pr-check.yml`
  - Builds the same Docker image used locally
  - Runs build + checks in container
- Publish workflow: `.github/workflows/site-publish.yml`
  - Builds on pushes to `asf-site`
  - Commits generated publish files back to `asf-site` via GitHub Actions

Note: `.build/` is ignored in `.gitignore` and is never pushed.

## Contributor Guide

See `CONTRIBUTING.md` for branch/PR workflow and validation checklist.
