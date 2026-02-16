# fineract-site

This is the Apache Fineract Website served on https://fineract.apache.org

See [CONTRIBUTING.md](CONTRIBUTING.md) for local run/test instructions before opening a PR.

## wish list

- [ ] clean up unused code/static assets (fonts, icons, images, etc)
- [ ] use a static site generator, don't hand-code HTML
    - [ ] validate links, markup, css, etc.
- [ ] auto-deploy website with every PR using an ASF tool or GitHub actions (commits to the asf-site branch do currently trigger auto-deploys, but this isn't set up for PRs)
- [ ] automate deployment of generated versioned asciidoc (don't commit it to apache/fineract-site repo – this creates a 2nd source of truth)
- [ ] fix text overlap with intermediate-sized media query
- [ ] document how to test locally, before/while committing
- [ ] additional review/critique of work done in https://github.com/apache/fineract-site/pull/37
- [x] improve [a11y](https://www.accessibilitychecker.org/audit/?website=https%3A%2F%2Ffineract.apache.org&flag=us) (accessibility) - current score of 57 out of 100, with 30 critical issues (as of 2026-02-11, only one issue remains)
- [x] fix [missing fonts and icons](https://github.com/apache/fineract-site/pull/38#issuecomment-2916819388)
- [x] [Cache google assets](https://github.com/apache/fineract-site/pull/37)
- [x] https://github.com/apache/fineract-site/pull/37
- [x] [migrate this wish list from Fineract JIRA](https://issues.apache.org/jira/browse/FINERACT-2192)
