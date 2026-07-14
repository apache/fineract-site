#!/usr/bin/env python3
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
"""Copy generated Fineract API docs from a backend clone into docs/VERSION.

Assumes the backend (apache/fineract) has already been built with
`./gradlew asciidoctor` and is available at --backend-dir (or
$FINERACT_REPO_DIR), e.g. mounted as a Docker volume.
"""

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_BACKEND_DIR = "/fineract"
DOC_HTML_RELATIVE_PATH = Path("fineract-doc/build/docs/html/en/index.html")

# Same substitution made by hand in commits like e70425660b42fc705760006141078e870df0a566.
GOOGLE_FONTS_LINK = (
    '<link rel="stylesheet" href="https://fonts.googleapis.com/css?family='
    "Open+Sans:300,300italic,400,400italic,600,600italic%7CNoto+Serif:400,"
    '400italic,700,700italic%7CDroid+Sans+Mono:400,700">'
)
LOCAL_STYLESHEET_LINK = '<link rel="stylesheet" href="../../css/stylesheet.css">'
FONT_AWESOME_CDN_LINK = (
    '<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/'
    'font-awesome/4.7.0/css/font-awesome.min.css">'
)
FONT_AWESOME_LOCAL_LINK = '<link rel="stylesheet" href="../../css/font-awesome.min.css">'


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--version",
        default=os.environ.get("FINERACT_DOC_VERSION"),
        help="Doc version folder to write, e.g. 1.16.0-SNAPSHOT "
        "(default: $FINERACT_DOC_VERSION)",
    )
    parser.add_argument(
        "--backend-dir",
        default=os.environ.get("FINERACT_REPO_DIR", DEFAULT_BACKEND_DIR),
        help="Path to the apache/fineract clone "
        f"(default: $FINERACT_REPO_DIR or {DEFAULT_BACKEND_DIR})",
    )
    args = parser.parse_args()
    if not args.version:
        parser.error("a version is required: pass --version or set FINERACT_DOC_VERSION")
    return args


def run_git(backend_dir, *git_args):
    return subprocess.run(
        ["git", "-C", str(backend_dir), *git_args],
        check=True,
        capture_output=True,
        text=True,
    )


def require_clean_git_status(backend_dir):
    result = run_git(backend_dir, "status", "--porcelain")
    if result.stdout.strip():
        sys.exit(
            f"Backend clone at {backend_dir} is not clean (git status --porcelain "
            "reported changes). Commit or stash them so the copied doc can be "
            f"traced back to an exact commit:\n{result.stdout}"
        )


def get_commit_hash(backend_dir):
    return run_git(backend_dir, "rev-parse", "HEAD").stdout.strip()


def localize_stylesheets(html_path):
    text = html_path.read_text(encoding="utf-8")
    text = text.replace(GOOGLE_FONTS_LINK, LOCAL_STYLESHEET_LINK)
    text = text.replace(FONT_AWESOME_CDN_LINK, FONT_AWESOME_LOCAL_LINK)
    if not text.endswith("\n"):
        text += "\n"
    html_path.write_text(text, encoding="utf-8")


def main():
    args = parse_args()
    backend_dir = Path(args.backend_dir)

    if not backend_dir.is_dir():
        sys.exit(f"Backend directory not found: {backend_dir}")

    source_html = backend_dir / DOC_HTML_RELATIVE_PATH
    if not source_html.is_file():
        sys.exit(
            f"{source_html} not found. Generate it first by running "
            "'./gradlew asciidoctor' in the backend clone."
        )

    require_clean_git_status(backend_dir)
    commit_hash = get_commit_hash(backend_dir)
    print(f"Backend commit: {commit_hash}")

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as f:
            f.write(f"fineract_commit={commit_hash}\n")

    dest_dir = REPO_ROOT / "docs" / args.version
    dest_html = dest_dir / "index.html"
    is_snapshot = args.version.endswith("-SNAPSHOT")

    if dest_html.exists() and not is_snapshot:
        sys.exit(
            f"{dest_html} already exists and {args.version} is not a -SNAPSHOT "
            "version. Refusing to overwrite a released doc."
        )

    dest_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_html, dest_html)
    localize_stylesheets(dest_html)

    print(f"Wrote {dest_html}")


if __name__ == "__main__":
    main()
