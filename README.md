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

   Install Graphviz (`dot`), plus `vl2vg` and `vg2svg` (`npm install -g vega-cli
   vega-lite`), first. Without them the build still succeeds but leaves
   diagrams out: PlantUML draws a "Cannot find Graphviz" error image in place of
   each of its diagrams. `fineract-site docs` refuses such a page, and
   `fineract-site build` fails on any already in `docs/`
   (`scripts/check_doc_diagrams.py`). After installing Graphviz, delete
   `fineract-doc/build` before rebuilding, as generated diagrams are cached.

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
versions are not, unless you pass `--replace-release` to republish one from the
same release tag (e.g. to fix a broken build).

It also suggests a commit message. Use it like so:

```bash
git commit -F DOCS-LOG-MESSAGE
```

Then point the matching `/docs/` alias at it, which also stages the change and
adds a note to `DOCS-LOG-MESSAGE`:

```bash
python3 .github/scripts/docs_aliases.py --version 1.17.0 --alias stable
python3 .github/scripts/docs_aliases.py --version 1.18.0-SNAPSHOT --alias develop
```

`stable` points `/docs/stable` (and so `/docs/current`) at a release. `develop`
points `/docs/develop` at a `-SNAPSHOT` and the commented `/docs/rc` candidate
at the release after it, and when the snapshot version has rolled, removes the
previous snapshot folder so Git records a rename instead of keeping both. With
no new release it changes nothing.

### Automated docs sync

`.github/workflows/docs-sync.yml` does all of the above every Monday and opens
a PR against `asf-site`:

- `develop` → refreshes `docs/X.Y.Z-SNAPSHOT` (`/docs/develop`), skipped when
  `develop` has not moved or only the build timestamp changed.
- The newest `X.Y.Z` release tag with no `docs/X.Y.Z/` yet → adds it and
  points `/docs/stable` at it.

Run it by hand from the Actions tab (`ref`, `dry_run` and `force` inputs).

The workflow only calls `.github/scripts/docs-sync.sh` and
`.github/scripts/docs-sync-pr.sh`, so it can be verified locally with the same
commands. Needs Java 25, Graphviz, Node.js, `jq` and Docker:

```bash
npm ci --prefix .github/docs-sync --ignore-scripts
export PATH="$PWD/.github/docs-sync/node_modules/.bin:$PATH"

.github/scripts/docs-sync.sh plan                  # what a scheduled run would build
.github/scripts/docs-sync.sh build develop develop # or: build 1.16.0 stable
ALIAS=develop VERSION=1.17.0-SNAPSHOT .github/scripts/docs-sync-pr.sh
```

`build` clones apache/fineract into `.build/fineract` (override with
`BACKEND_DIR`) and leaves the result staged, as the workflow would commit it.

Unit tests and workflow lint:

```bash
docker run --rm -v "$PWD:/src" -w /src/site-src fineract-site test
docker run --rm -v "$PWD:/repo:ro" -w /repo ghcr.io/zizmorcore/zizmor --persona=pedantic .github/workflows/docs-sync.yml
docker run --rm -v "$PWD:/repo:ro" -w /repo rhysd/actionlint .github/workflows/docs-sync.yml
docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck .github/scripts/docs-sync.sh .github/scripts/docs-sync-pr.sh
```

## Verifying ASF project website compliance

Apache Whimsy periodically checks that the public homepage follows ASF conventions.
Output of these checks is displayed [here](https://whimsy.apache.org/site/project/fineract).

## Contributor Guide

See `CONTRIBUTING.md` for CI/CD details and branch/PR workflow.
