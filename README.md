# fineract-site

Apache Fineract website source repository for <https://fineract.apache.org>, a Hugo-generated static website.

## Prerequisites

- Git
- Docker

## Guide to this repository

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

## Issue tracker

Issues are in [GitHub](https://github.com/apache/fineract-site/issues) as of July 20, 2026.
Older ones are in [JIRA](https://issues.apache.org/jira/browse/FINERACT-2664?jql=project%20%3D%20FINERACT%20AND%20component%20%3D%20website).

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

## Updating `/docs/VERSION` from a Fineract backend clone

`docs/VERSION` (e.g. `docs/1.16.0-SNAPSHOT`) holds the rendered Fineract API
documentation built from the [apache/fineract](https://github.com/apache/fineract)
backend. To refresh it:

1. In your clone of `apache/fineract`, generate the docs:

   ```bash
   ./gradlew asciidoctor
   ```

   Make sure the clone's working tree is clean (`git status`) -- the commit hash
   is recorded so the copied doc can be traced back to the exact source commit.

2. Run the `docs` command in the site tool image, mounting both repos:

   ```bash
   docker run --rm -u "$(id -u):$(id -g)" \
     -v "$PWD:/src" \
     -v /path/to/fineract:/fineract:ro \
     -w /src \
     fineract-site docs --version 1.16.0-SNAPSHOT
   ```

   The version can also be set via `FINERACT_DOC_VERSION`, and the backend
   mount path via `FINERACT_REPO_DIR` (default `/fineract`).

This copies `fineract-doc/build/docs/html/en/index.html` from the backend clone
into `docs/VERSION/index.html`, then rewrites the Google Fonts and Font Awesome
CDN links to point at the site's local `css/` stylesheets (per Apache project
website requirements). Versions ending in `-SNAPSHOT` are overwritten; released
versions are not.

It also suggests a commit message. Use it like so:

```bash
git commit -F DOCS-LOG-MESSAGE
```

## Verifying ASF project website compliance

Apache Whimsy periodically checks that the public homepage follows ASF conventions.
Output of these checks is displayed [here](https://whimsy.apache.org/site/project/fineract).

## Contributor Guide

See `CONTRIBUTING.md` for CI/CD details and branch/PR workflow.
