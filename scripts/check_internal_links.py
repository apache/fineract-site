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
"""Check internal links in generated static HTML files."""

import argparse
import re
import sys
from pathlib import Path
from typing import List, Optional, Tuple
from urllib.parse import unquote, urlsplit

LINK_PATTERN = re.compile(r"""(?:href|src)\s*=\s*["']([^"']+)["']""", re.IGNORECASE)

INTERNAL_HOSTS = {"fineract.apache.org", "www.fineract.apache.org"}
IGNORED_PREFIXES = ("mailto:", "tel:", "javascript:", "data:")


def parse_rewrite_prefixes(htaccess_path: Path) -> List[Tuple[str, str]]:
    """Parse simple prefix rewrites from .htaccess for link validation."""
    rewrites: List[Tuple[str, str]] = []
    if not htaccess_path.is_file():
        return rewrites

    # Example:
    # RewriteRule ^docs/current(.*)$ docs/1.14.0$1 [L]
    pattern = re.compile(r"^RewriteRule\s+\^([^\s]+)\s+([^\s]+)\s+\[")
    for raw_line in htaccess_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw_line.strip()
        match = pattern.match(line)
        if not match:
            continue

        source = match.group(1)
        destination = match.group(2)

        source_prefix = None
        if source.endswith("(.*)$"):
            source_prefix = "/" + source[: -len("(.*)$")].rstrip("/")
        elif source.endswith("$"):
            source_prefix = "/" + source[:-1].rstrip("/")
        if not source_prefix:
            continue

        if "$1" in destination:
            destination_prefix = "/" + destination.split("$1", maxsplit=1)[0].rstrip("/")
        else:
            destination_prefix = "/" + destination.rstrip("/")
        rewrites.append((source_prefix, destination_prefix))

    return rewrites


def apply_rewrites(path: str, rewrites: List[Tuple[str, str]]) -> str:
    rewritten = path
    # Small max depth to avoid accidental rewrite loops.
    for _ in range(8):
        changed = False
        for source_prefix, destination_prefix in rewrites:
            if rewritten == source_prefix or rewritten.startswith(source_prefix + "/"):
                suffix = rewritten[len(source_prefix) :]
                rewritten = destination_prefix + suffix
                changed = True
                break
        if not changed:
            return rewritten
    return rewritten


def candidate_paths(base_path: Path, trailing_slash: bool) -> List[Path]:
    if trailing_slash:
        return [base_path / "index.html"]
    if base_path.suffix:
        return [base_path]
    return [base_path, Path(str(base_path) + ".html"), base_path / "index.html"]


def resolve_link_target(
    link: str,
    source_file: Path,
    site_root: Path,
    rewrite_prefixes: List[Tuple[str, str]],
) -> Optional[List[Path]]:
    if not link:
        return None

    lower_link = link.lower()
    if lower_link.startswith(IGNORED_PREFIXES):
        return None
    if link.startswith("#") or link.startswith("//"):
        return None

    parsed = urlsplit(link)

    # External links are out of scope for this internal checker.
    if parsed.scheme in ("http", "https"):
        if parsed.netloc not in INTERNAL_HOSTS:
            return None
        link_path = parsed.path or "/"
        link_path = apply_rewrites(link_path, rewrite_prefixes)
        trailing_slash = link_path.endswith("/")
        relative_path = Path(unquote(link_path.lstrip("/")))
        return candidate_paths(site_root / relative_path, trailing_slash)

    # Ignore pseudo-links like query-only references.
    if not parsed.path:
        return None

    trailing_slash = parsed.path.endswith("/")
    decoded_path = unquote(parsed.path)

    if decoded_path.startswith("/"):
        root_path = apply_rewrites(decoded_path, rewrite_prefixes)
        target_base = site_root / Path(root_path.lstrip("/"))
    else:
        target_base = (source_file.parent / Path(decoded_path)).resolve()

    # Prevent directory traversal outside build root.
    try:
        target_base.relative_to(site_root.resolve())
    except ValueError:
        return []

    return candidate_paths(target_base, trailing_slash)


def check_internal_links(site_root: Path, include_docs: bool) -> Tuple[int, List[str]]:
    site_root = site_root.resolve()
    rewrite_prefixes = parse_rewrite_prefixes(site_root / ".htaccess")
    errors: List[str] = []

    html_files = sorted(site_root.rglob("*.html"))
    for html_file in html_files:
        relative_html = html_file.relative_to(site_root)
        if not include_docs and relative_html.parts and relative_html.parts[0] == "docs":
            continue
        content = html_file.read_text(encoding="utf-8", errors="ignore")
        for match in LINK_PATTERN.finditer(content):
            link = match.group(1).strip()
            candidates = resolve_link_target(link, html_file, site_root, rewrite_prefixes)
            if candidates is None:
                continue
            if not candidates or not any(candidate.is_file() for candidate in candidates):
                rel_source = html_file.relative_to(site_root)
                errors.append(f"{rel_source}: missing target for '{link}'")

    return len(errors), errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate internal links in generated HTML output.")
    parser.add_argument(
        "--site-root",
        default=".build/site",
        help="Path to generated site root (default: .build/site).",
    )
    parser.add_argument(
        "--include-docs",
        action="store_true",
        help="Include legacy /docs HTML files in link validation.",
    )
    args = parser.parse_args()

    site_root = Path(args.site_root)
    if not site_root.is_dir():
        print(f"Site root not found: {site_root}", file=sys.stderr)
        return 2

    count, errors = check_internal_links(site_root, args.include_docs)
    if count:
        print(f"Internal link check failed: {count} broken link(s) found.", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Internal link check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
