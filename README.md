# fineract-site

Apache Fineract website source repository for <https://fineract.apache.org>, a Hugo-generated static website.

## Prerequisites

- Git
- Docker

## What's where

- Sources are in `site-src/` (OK to edit)
- Static assets (published as-is, OK to edit)
  - `docs/` → `/docs/`
  - `css/` → `/css/`
  - `js/` → `/js/`
  - `images/` → `/images/`
  - `font/` → `/font/`
  - `.htaccess` → `/.htaccess`
  - `doap_Fineract.rdf` → `/doap_Fineract.rdf`
- Generated output is in `.build/site` (do not edit)

## Local Build and Checks (Docker)

1. Build the site tool image:

```bash
docker build -t fineract-site .
```

2. Build site and run checks:

```bash
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/src" -w /src/site-src fineract-site build
```

3. Serve locally with watch mode:

```bash
docker run --rm -it -u "$(id -u):$(id -g)" -v "$PWD:/src" -w /src/site-src -p 1313:1313 fineract-site serve
```

4. Optional: run checks only (without rebuilding):

```bash
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/src" -w /src/site-src fineract-site check
```

Windows PowerShell equivalent (no UID/GID mapping):

```powershell
docker build -t fineract-site .
docker run --rm -v "${PWD}:/src" -w /src/site-src fineract-site build
docker run --rm -it -p 1313:1313 -v "${PWD}:/src" -w /src/site-src fineract-site serve
```

## Verifying ASF project website compliance

Apache Whimsy periodically checks that the public homepage follows ASF conventions.
Output of these checks is displayed [here](https://whimsy.apache.org/site/project/fineract).

## Contributor Guide

See `CONTRIBUTING.md` for CI/CD details and branch/PR workflow.
