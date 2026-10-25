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
"""Point a /docs/ alias at a version that `fineract-site docs` just copied.

Run by .github/scripts/docs-sync.sh after `fineract-site docs --version
VERSION`, and usable by hand the same way. It makes the follow-up changes done
by hand so far, stages them, and adds a note for each to DOCS-LOG-MESSAGE:

- stable: points /docs/stable (and so /docs/current) at a release.
- develop: points /docs/develop at a -SNAPSHOT and the commented /docs/rc
  candidate at the release after it. When the snapshot version has rolled, it
  also removes the previous snapshot folder, so Git records docs/OLD ->
  docs/NEW as a rename rather than keeping both (as in 3c4e0c1a).

With no new release, a develop run changes nothing here: the snapshot page is
updated in place.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def alias_rule(alias, commented=False):
    """Match an .htaccess line like `RewriteRule ^docs/stable(.*)$ docs/1.16.0$1 [L]`.

    Group 2 is the version folder the alias points at.
    """
    prefix = "#" if commented else ""
    return re.compile(
        rf"^({prefix}RewriteRule \^docs/{alias}\(\.\*\)\$ docs/)([^$\s]+)(\$1 \[L\])$",
        re.MULTILINE,
    )


STABLE_RULE = alias_rule("stable")
DEVELOP_RULE = alias_rule("develop")
# Only the commented-out candidate; the active /docs/rc stub points at stable.
RC_CANDIDATE_RULE = alias_rule("rc", commented=True)


def alias_target(htaccess, rule):
    match = rule.search(htaccess)
    if not match:
        sys.exit(f"No .htaccess line matching {rule.pattern}")
    return match.group(2)


def retarget(htaccess, rule, version):
    alias_target(htaccess, rule)
    return rule.sub(lambda m: f"{m.group(1)}{version}{m.group(3)}", htaccess, count=1)


def release_of(snapshot_version):
    return snapshot_version[: -len("-SNAPSHOT")]


def update_aliases(htaccess, alias, version):
    """Return (new .htaccess text, notes for the commit message)."""
    notes = []
    if alias == "stable":
        if alias_target(htaccess, STABLE_RULE) != version:
            htaccess = retarget(htaccess, STABLE_RULE, version)
            notes.append(
                f"Point the /docs/stable alias (and /docs/current, which redirects "
                f"to it) at {version} in .htaccess."
            )
    elif alias == "develop":
        if alias_target(htaccess, DEVELOP_RULE) != version:
            htaccess = retarget(htaccess, DEVELOP_RULE, version)
            notes.append(f"Point the /docs/develop alias at {version} in .htaccess.")
        if alias_target(htaccess, RC_CANDIDATE_RULE) != release_of(version):
            htaccess = retarget(htaccess, RC_CANDIDATE_RULE, release_of(version))
            notes.append(
                f"Point the commented-out /docs/rc candidate at {release_of(version)} "
                "in .htaccess."
            )
    return htaccess, notes


def previous_snapshot(htaccess, version, docs_dir):
    """The snapshot folder /docs/develop pointed at before VERSION, if it should go."""
    previous = alias_target(htaccess, DEVELOP_RULE)
    if previous == version or not (docs_dir / previous).is_dir():
        return None
    return previous


def git(repo_root, *args):
    result = subprocess.run(["git", "-C", str(repo_root), *args], capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"git {' '.join(args)} failed in {repo_root}:\n{result.stderr}")


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--version", required=True, help="Version just copied, e.g. 1.17.0-SNAPSHOT")
    parser.add_argument("--alias", required=True, choices=["stable", "develop"])
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=REPO_ROOT,
        help=f"fineract-site clone (default: {REPO_ROOT})",
    )
    args = parser.parse_args()
    is_snapshot = args.version.endswith("-SNAPSHOT")
    if args.alias == "stable" and is_snapshot:
        parser.error("--alias stable needs a released version, not a -SNAPSHOT")
    if args.alias == "develop" and not is_snapshot:
        parser.error("--alias develop needs a -SNAPSHOT version")
    return args


def main():
    args = parse_args()
    root = args.repo_root
    htaccess_path = root / ".htaccess"
    message_path = root / "DOCS-LOG-MESSAGE"
    if not (root / "docs" / args.version / "index.html").is_file():
        sys.exit(f"docs/{args.version}/index.html not found; run `fineract-site docs` first")
    if not message_path.is_file():
        sys.exit(f"{message_path} not found; run `fineract-site docs` first")

    htaccess = htaccess_path.read_text(encoding="utf-8")
    notes = []

    if args.alias == "develop":
        previous = previous_snapshot(htaccess, args.version, root / "docs")
        if previous:
            git(root, "rm", "-r", "--quiet", f"docs/{previous}")
            print(f"Removed docs/{previous}; Git records it as renamed to docs/{args.version}")
            notes.append(f"Rename docs/{previous} to docs/{args.version} rather than keeping both.")

    new_htaccess, alias_notes = update_aliases(htaccess, args.alias, args.version)
    if alias_notes:
        htaccess_path.write_text(new_htaccess, encoding="utf-8")
        git(root, "add", ".htaccess")
        print("Updated and staged .htaccess")
        notes.extend(alias_notes)

    if notes:
        message = message_path.read_text(encoding="utf-8").rstrip("\n")
        message_path.write_text(message + "".join(f"\n\n{note}" for note in notes), encoding="utf-8")
    else:
        print(f"/docs/{args.alias} already points at {args.version}; nothing to change")


if __name__ == "__main__":
    main()
