#!/usr/bin/env bash
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
# Rebuilds /docs/ from apache/fineract. This is what
# .github/workflows/docs-sync.yml runs, and it runs the same way locally.
#
# Usage:
#   .github/scripts/docs-sync.sh plan [REF]
#       Print the targets to build as JSON, e.g. [{"ref":"develop","alias":"develop"}].
#       With no REF: develop, unless the snapshot docs already came from its
#       head (FORCE=true rebuilds anyway), plus the newest X.Y.Z tag if it has
#       no docs/X.Y.Z/ yet.
#   .github/scripts/docs-sync.sh build REF ALIAS
#       Build REF's docs and stage them via `fineract-site docs`, then the
#       .htaccess change via docs_aliases.py (ALIAS is stable or develop).
#
# Needs git, jq, Java 25, Docker, Graphviz (dot), and vl2vg/vg2svg on the PATH:
#   npm ci --prefix .github/docs-sync && export PATH="$PWD/.github/docs-sync/node_modules/.bin:$PATH"
#
# Environment:
#   BACKEND_DIR  apache/fineract clone to build in, created if missing
#                (default: .build/fineract, which Git and Docker ignore)
#   FORCE        "true" to rebuild develop even when it has not moved
#
# Results go to $GITHUB_OUTPUT and $GITHUB_STEP_SUMMARY in Actions, and to the
# terminal otherwise.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UPSTREAM="https://github.com/apache/fineract.git"
BACKEND_DIR="${BACKEND_DIR:-${REPO_ROOT}/.build/fineract}"
OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stderr}"

usage() {
  sed -n '/^# Usage:/,/^# terminal otherwise/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

check_ref() {
  if ! [[ "$1" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    echo "Unexpected characters in ref: $1" >&2
    exit 1
  fi
}

is_release() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

plan() {
  local targets='[]'
  add() {
    targets="$(jq -c --arg ref "$1" --arg alias "$2" '. + [{ref: $ref, alias: $alias}]' <<<"$targets")"
    echo "Will build $1 (/docs/$2)" >>"$SUMMARY"
  }

  if [ -n "${1:-}" ]; then
    check_ref "$1"
    if is_release "$1"; then add "$1" stable; else add "$1" develop; fi
  else
    local head_sha last_sha tag
    head_sha="$(git ls-remote "$UPSTREAM" refs/heads/develop | cut -f1)"
    # `fineract-site docs` records the backend commit in each docs commit message.
    last_sha="$(git -C "$REPO_ROOT" log -1 --format=%B -E --grep='^update /docs/[0-9.]+-SNAPSHOT$' |
      grep -oE 'apache/fineract/commit/[0-9a-f]{40}' | cut -d/ -f4 || true)"
    if [ "${FORCE:-false}" = "true" ] || [ "$head_sha" != "$last_sha" ]; then
      add develop develop
    else
      echo "develop is still at $last_sha, which the snapshot docs were built from." >>"$SUMMARY"
    fi

    tag="$(git ls-remote --tags --refs "$UPSTREAM" |
      sed -n 's#.*refs/tags/\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$#\1#p' | sort -V | tail -1)"
    if [ -n "$tag" ] && [ ! -e "$REPO_ROOT/docs/$tag/index.html" ]; then
      add "$tag" stable
    fi
  fi
  echo "targets=$targets" >>"$OUTPUT"
}

checkout_backend() {
  local ref="$1"
  if [ -d "$BACKEND_DIR/.git" ]; then
    git -C "$BACKEND_DIR" fetch --quiet --tags --force origin
  else
    # Full history (blobs fetched lazily): the backend derives its version
    # from the tags in its history, so a shallow clone builds as 0.0.0.
    git clone --quiet --filter=blob:none "$UPSTREAM" "$BACKEND_DIR"
  fi
  if git -C "$BACKEND_DIR" rev-parse --verify --quiet "refs/remotes/origin/$ref" >/dev/null; then
    git -C "$BACKEND_DIR" checkout --quiet --detach "origin/$ref"
  else
    git -C "$BACKEND_DIR" checkout --quiet --detach "$ref"
  fi
  git -C "$BACKEND_DIR" log -1 --format='Building apache/fineract %H (%s)'
}

build() {
  local ref="$1" alias="$2" log version html
  check_ref "$ref"
  case "$alias" in stable | develop) ;; *) usage ;; esac
  if is_release "$ref" && [ "$alias" != "stable" ]; then
    echo "Release tag $ref takes the stable alias" >&2
    exit 1
  fi

  # asciidoctor-diagram shells out to these for the Vega-Lite diagrams. Without
  # them the build still succeeds but leaves the diagrams out.
  for tool in vl2vg vg2svg; do
    if ! command -v "$tool" >/dev/null; then
      echo "$tool is not on the PATH. Run: npm ci --prefix .github/docs-sync" \
        "&& export PATH=\"\$PWD/.github/docs-sync/node_modules/.bin:\$PATH\"" >&2
      exit 1
    fi
  done
  # PlantUML needs Graphviz for most diagrams. Without it the build also
  # succeeds, with a "Cannot find Graphviz" image in place of each one
  # (see scripts/check_doc_diagrams.py).
  if ! command -v dot >/dev/null; then
    echo "dot is not on the PATH. Install Graphviz, e.g. sudo apt-get install graphviz" >&2
    exit 1
  fi

  checkout_backend "$ref"

  log="$REPO_ROOT/.build/asciidoctor.log"
  mkdir -p "$(dirname "$log")"
  # A reused clone may hold diagrams rendered before a tool was installed, and
  # asciidoctor-diagram would keep them; Gradle cannot see that either.
  rm -rf "$BACKEND_DIR/fineract-doc/build"
  (cd "$BACKEND_DIR" && ./gradlew --no-daemon --console=plain :fineract-doc:asciidoctor) 2>&1 | tee "$log"
  if grep -q 'Failed to generate image' "$log"; then
    grep 'Failed to generate image' "$log" >&2
    echo "Some diagrams were not generated" >&2
    exit 1
  fi

  # The rendered page carries the version Gradle derived, which is the folder
  # name the docs belong in.
  html="$BACKEND_DIR/fineract-doc/build/docs/html/en/index.html"
  version="$(grep -oE 'id="revnumber">version [^<]+' "$html" | sed 's/.*version //')"
  if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-SNAPSHOT)?$ ]]; then
    echo "Unexpected docs version '$version'" >&2
    exit 1
  fi
  if [ "$alias" = "stable" ] && [ "$version" != "$ref" ]; then
    echo "Tag $ref built as version $version" >&2
    exit 1
  fi
  echo "version=$version" >>"$OUTPUT"
  echo "Docs version: $version" >>"$SUMMARY"

  cd "$REPO_ROOT"
  docker build -t fineract-site .
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$REPO_ROOT:/src" \
    -v "$BACKEND_DIR:/fineract:ro" \
    -w /src \
    fineract-site docs --version "$version"
  python3 "$REPO_ROOT/.github/scripts/docs_aliases.py" --version "$version" --alias "$alias"

  # Every build stamps fresh "Built on" and "Last updated" lines, so a develop
  # build with no real doc change would otherwise propose a change every week.
  local other content
  other="$(git diff --cached --name-status | grep -v $'^M\tdocs/[^/]*/index.html$' || true)"
  content="$(git diff --cached -U0 -- docs | grep -E '^[-+]' | grep -vE '^(\+\+\+|---)' |
    grep -vE '^[-+](<p><strong>Built on</strong>: .*</p>|Last updated .*)$' || true)"
  if [ -z "$other" ] && [ -z "$content" ]; then
    echo "changed=false" >>"$OUTPUT"
    echo "Only the build timestamp changed; nothing to propose." >>"$SUMMARY"
    return
  fi
  echo "changed=true" >>"$OUTPUT"
  git diff --cached --stat >>"$SUMMARY"

  # The same build and checks as site-pr-check.yml.
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -v "$REPO_ROOT:/src" \
    -w /src/site-src \
    fineract-site build
}

case "${1:-}" in
  plan)
    plan "${2:-}"
    ;;
  build)
    [ $# -eq 3 ] || usage
    build "$2" "$3"
    ;;
  *)
    usage
    ;;
esac
