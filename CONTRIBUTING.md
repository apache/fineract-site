# Contributing to Apache Fineract Site

First off, thank you for considering contributing to the
[Apache Fineract Site](https://fineract.apache.org/).

We welcome contributions of all sizes, from fixing issues to updating design
layouts. This guide is intended to make your contribution experience as smooth
as possible.

## Table of Contents

- [Contributing to Apache Fineract Site](#contributing-to-apache-fineract-site)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites and Tools](#prerequisites-and-tools)
  - [Getting Started](#getting-started)
    - [1. Fork and Clone](#1-fork-and-clone)
    - [2. Branching Strategy](#2-branching-strategy)
  - [Development Workflow](#development-workflow)
    - [Project Structure](#project-structure)
    - [Coding Standards](#coding-standards)
  - [Running Locally](#running-locally)
  - [Testing and Verification](#testing-and-verification)
    - [1. Visual Regression](#1-visual-regression)
    - [2. Functional Testing](#2-functional-testing)
    - [3. Git Sanity Check](#3-git-sanity-check)
  - [Submission Guidelines](#submission-guidelines)
    - [Commit Messages](#commit-messages)
    - [Opening a Pull Request (PR)](#opening-a-pull-request-pr)
  - [Community and Help](#community-and-help)

## Prerequisites and Tools

This repository is a static site consisting of HTML, CSS, and JavaScript.

Recommended tools:

1. Editor: [VS Code](https://code.visualstudio.com/) (recommended)
2. Extension:
   [Live Server](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer)
   for VS Code
3. Browser: Chrome, Firefox, or Safari (use developer tools/console)
4. Version control: Git CLI

## Getting Started

### 1. Fork and Clone

Since this is an open source project, we recommend using the Fork and Pull
model.

1. Fork the repository to your own GitHub account.
2. Clone your fork locally:

```bash
git clone https://github.com/<your-username>/fineract-site.git
cd fineract-site
```

3. Add upstream remote to keep your fork synced:

```bash
git remote add upstream https://github.com/apache/fineract-site.git
```

### 2. Branching Strategy

Important: the default and active branch for this repository is `asf-site`.

1. Always create a new branch for your changes.
2. Use short, descriptive branch names (for example:
   `fix-nav-typo`, `feat-dark-mode-update`).

```bash
# Update your local source
git checkout asf-site
git pull upstream asf-site

# Create your feature branch
git checkout -b <type>-<description>
```

## Development Workflow

### Project Structure

1. `index.html`: main landing page
2. `css/`: stylesheets
3. `js/`: scripts for logic (theme toggle, navigation, and so on)
4. `images/`: images and icons

### Coding Standards

1. HTML: ensure semantic usage of tags.
2. CSS: avoid inline styles where possible; use defined CSS classes.
3. JavaScript: keep code clean and remove debug `console.log` before pushing.
4. Formatting: maintain consistent indentation and style used in existing files.

## Running Locally

Since this is a static site, use a local web server. Opening HTML files directly
can cause broken links or missing assets in some environments.

Option A: VS Code Live Server (recommended)

1. Open the `fineract-site` folder in VS Code.
2. Right-click `index.html` in the file explorer.
3. Select `Open with Live Server`.
4. The site will launch at `http://127.0.0.1:5500` (or similar).

Option B: Python simple server (optional)

```bash
# Inside the root directory
python -m http.server 8000
```

Then navigate to `http://localhost:8000`.

## Testing and Verification

There is currently no automated CI workflow for this repository. Manual
verification is required.

Please complete this checklist before committing.

### 1. Visual Regression

- [ ] Theme support: toggle light/dark mode and verify icon/text readability.
- [ ] Responsiveness: test desktop, tablet, and mobile viewports.
- [ ] Navigation: verify mobile menu opens/closes correctly.

### 2. Functional Testing

- [ ] Console errors: no red JavaScript errors in browser dev tools.
- [ ] Links: click through changed areas and verify no broken pages.
- [ ] Routing: verify `/index.html`, `/security.html`, and `/404.html`.

### 3. Git Sanity Check

Check for unintended file changes or whitespace issues:

```bash
git status
git diff --check
```

## Submission Guidelines

### Commit Messages

Use clear, descriptive commit messages.

Bad:

```text
fixed stuff
```

Good:

```text
fix(nav): correct alignment on mobile menu
```

### Opening a Pull Request (PR)

1. Push your branch to your fork:

```bash
git push origin <your-branch-name>
```

2. Open a PR against the `asf-site` branch of the upstream repository.

PR checklist (include in PR description):

1. Summary: what changed and why
2. Issue link: for example, `Fixes #123` (if applicable)
3. Testing: how you validated changes locally
4. Screenshots: required for UI changes (desktop and mobile)

## Community and Help

If you have questions, reach out via:

1. Mailing list: `dev@fineract.apache.org`
2. Issue tracker: [Apache Jira](https://issues.apache.org/jira/projects/FINERACT/summary)
