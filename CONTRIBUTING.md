# Contributing To Apache Fineract Site

Thanks for contributing to https://fineract.apache.org.

## Prerequisites

1. Git
2. Docker

## Source Model

1. Hugo sources are in `site-src/`.
2. Generated output is `.build/site` and should not be edited directly.
3. Static assets are mounted from repository root folders (`css/`, `js/`, `images/`, `font/`, `docs/`).

## Local Development

1. Build tooling image:

```bash
docker build -t fineract-site .
```

2. Build and validate:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site build
```

3. Serve locally:

```bash
docker run --rm -it \
  --user "$(id -u):$(id -g)" \
  -p 1313:1313 \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site serve
```

4. Optional checks-only run:

```bash
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/src" \
  -w /src/site-src \
  fineract-site check
```

Windows PowerShell equivalents:

```powershell
docker build -t fineract-site .
docker run --rm -v "${PWD}:/src" -w /src/site-src fineract-site build
docker run --rm -it -p 1313:1313 -v "${PWD}:/src" -w /src/site-src fineract-site serve
```

4. Open `http://localhost:1313` and verify:
   - Home page (`/`)
   - Security page (`/security.html`)
   - Error page (`/404.html`)
   - Docs paths (`/docs/current/`, `/docs/legacy/`, `/docs/database/`)

## Editing Rules

1. Do not edit `.build/site`.
2. Do not re-introduce root hand-maintained HTML sources (`index.html`, `security.html`, `404.html`).
3. Add content/pages in Hugo (`site-src/content`, `site-src/layouts`, `site-src/data`).
4. Keep public URL paths stable unless an intentional migration is documented.

## Pull Requests

1. Create a feature branch from your source branch.
2. Commit only source changes, not generated output.
3. Ensure local checks pass before opening a PR:

```bash
docker build -t fineract-site .
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/src" -w /src/site-src fineract-site build
git status
```

4. In the PR description include:
   - What changed
   - Why it changed
   - How you tested locally
   - Screenshots for visual changes

## CI Workflows

1. PR checks: `.github/workflows/site-pr-check.yml`
2. Publish automation: `.github/workflows/site-publish.yml`

## Branch Model

1. Source branch is `asf-site`.
2. On push to `asf-site`, GitHub Actions builds the site and commits generated publish files to `asf-site`.
3. Do not commit `.build/` output; it is local-only and ignored by git.
