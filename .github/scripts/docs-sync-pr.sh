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
# Turns the DOCS-LOG-MESSAGE that `fineract-site docs` wrote into the inputs
# .github/workflows/docs-sync.yml hands to create-pull-request: the commit
# message, PR title, sync branch and PR body.
#
# A separate file so the workflow never interpolates ${{ }} into a script, and
# so the wording can be changed without touching YAML. Everything arrives
# through the environment:
#   ALIAS    stable or develop
#   VERSION  the docs version that was built
#   RUN_URL  link to the workflow run (optional)
#   OUT_DIR  where to write commit-message.txt and pr-body.md
#            (default: $RUNNER_TEMP, else .build)
#
# Outputs go to $GITHUB_OUTPUT in Actions and to the terminal otherwise.
#
# Usage: ALIAS=develop VERSION=1.17.0-SNAPSHOT .github/scripts/docs-sync-pr.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${OUT_DIR:-${RUNNER_TEMP:-${REPO_ROOT}/.build}}"
OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"
: "${ALIAS:?ALIAS is required}" "${VERSION:?VERSION is required}"

message_file="$OUT_DIR/commit-message.txt"
mkdir -p "$OUT_DIR"
# Moved, not copied: create-pull-request's add-paths would leave it alone, but
# a stray DOCS-LOG-MESSAGE in the tree would only confuse a later local run.
mv "$REPO_ROOT/DOCS-LOG-MESSAGE" "$message_file"

if [ "$ALIAS" = "stable" ]; then
  branch="bot/docs-$VERSION"
else
  # One branch for develop: a later run updates the open PR instead of adding one.
  branch="bot/docs-develop"
fi

# The delimiter cannot occur in a commit message `fineract-site docs` writes.
{
  echo "title=$(head -1 "$message_file")"
  echo "branch=$branch"
  echo "message<<DOCS_SYNC_EOF"
  cat "$message_file"
  echo
  echo "DOCS_SYNC_EOF"
  echo "body-path=$OUT_DIR/pr-body.md"
} >>"$OUTPUT"

{
  if [ -n "${RUN_URL:-}" ]; then
    echo "Rebuilt by the [Fineract Docs Sync]($RUN_URL) workflow."
  else
    echo "Rebuilt with \`.github/scripts/docs-sync.sh\`."
  fi
  echo
  echo '```'
  cat "$message_file"
  echo
  echo '```'
  echo
  echo "To preview, check out this branch and open \`docs/$VERSION/index.html\`."
} >"$OUT_DIR/pr-body.md"
