# Contributing

Thanks for contributing to <https://fineract.apache.org>, our [project web site](https://infra.apache.org/project-site.html)!

## Philosophy

Our high-level priorities:

### compliance

* [ASF project web site checks](https://whimsy.apache.org/site/project/fineract) should pass (all appear green).
* Markup and code should be well-formed, valid, free of errors and warnings.

### maintainability

* With every change, seek to improve and reduce code. Leave it better than you found it.
* Communicate your intent clearly. Leave good notes for future devs, including yourself. Use commit log messages to capture intent.

### speed

* The site should continue to load quickly and cleanly for as many visitors as possible.

## Prerequisites

1. Git
1. Docker

## Source Model

1. Hugo sources are in `site-src/`.
1. Generated output is `.build/site` and should not be edited directly.
1. Static assets are mounted from repository root folders (`css/`, `js/`, `images/`, `font/`, `docs/`).
1. Dev and CI tooling is in `Dockerfile`, `scripts/`, and `.github/workflows/`.

## Local Development

Build site tool image and run containers following instructions in `README.md`.

Serve the website, open `http://localhost:1313`, and inspect:

- [ ] Home page (`/`)
- [ ] Security page (`/security.html`)
- [ ] Error page (`/404.html`)
- [ ] Docs paths (`/docs/current/`, `/docs/legacy/`, `/docs/database/`)

## Editing Rules

1. Do not edit `.build/site`.
1. Do not re-introduce root hand-maintained HTML sources (`index.html`, `security.html`, `404.html`).
1. Add content/pages in Hugo (`site-src/content`, `site-src/layouts`, `site-src/data`).
1. Keep public URL paths stable unless an intentional migration is documented.

## Pull Requests

1. Clone/fork the repository.
1. Create a branch off `asf-site`.
1. Commit only source changes, not generated output.
1. Sign commits with a PGP/GPG key.
1. Ensure local checks pass.
1. In the PR description include:
   - What changed (briefly)
   - Why it changed (your intent!)
   - How you tested locally (automated runs, manual verification, etc.)
   - Screenshots for visual changes (before & after)
1. Use separate commits for whitespace/formatting changes (with no effect/output) and meaningful/impactful code changes.

When updating PRs with new changes, leave commits as-is/un-squashed. Try to avoid force-pushing. Use your best judgment here. In general, only squash/rebase/force push to correct mistakes/noise not helpful for posterity. If you do force push, make sure collaborators are aware. It's helpful for posterity / intent forensics to see progress along the way, changes reversed, etc. Ideally with commit log detail about the "why" for the changes, summaries of our discussions leading to the changes, ideas/plans for future changes, etc.

Note this methodology for source control (keeping a series of PR commits un-squashed) is a different policy than we use for [the apache/fineract repo](https://github.com/apache/fineract).

Do not sign commits with SSH keys. More info:

* https://stackoverflow.com/questions/51412164/gpg-vs-ssh-keys
* https://stackoverflow.com/questions/73489997/whats-the-difference-between-signing-commits-with-ssh-versus-gpg
* https://fineract.apache.org/docs/current/#_gpg_2

## CI Workflows

On push to `asf-site`, GitHub Actions builds the site, edits a clone of the `asf-site` in-place, then commits and pushes generated files.

* PR checks: `.github/workflows/site-pr-check.yml`
* Publish automation: `.github/workflows/site-publish.yml`
* Ensure commits are signed: `.github/workflows/verify-commits.yml`

## Code formatting

In general, follow the spacing and formatting conventions present in existing code/markup.

Additionally, there are some things you can do to ease human code reviews:

1. Do not add whitespace at ends of lines.
1. Ensure all files end with a newline.

We don't use linters/formatters, but we should consider that.
