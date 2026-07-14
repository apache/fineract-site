#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: site-tool <build|check|docs|serve|shell> [args...]

Commands:
  build  Build site into /src/.build/site and run checks
  check  Run internal link check against /src/.build/site
  docs   Copy generated Fineract API docs into /src/docs/VERSION
  test   Run unit tests for whimsy checks
  serve  Run hugo server on port 1313
  shell  Open an interactive shell
EOF
}

resolve_paths() {
  if [[ -f "config.toml" && -d "../scripts" ]]; then
    SITE_SRC_DIR="$(pwd)"
    REPO_ROOT="$(cd .. && pwd)"
    return
  fi
  if [[ -f "site-src/config.toml" && -d "scripts" ]]; then
    REPO_ROOT="$(pwd)"
    SITE_SRC_DIR="${REPO_ROOT}/site-src"
    return
  fi
  echo "Unable to locate repository root. Use -w /src or -w /src/site-src." >&2
  exit 2
}

build_site() {
  cd "${SITE_SRC_DIR}"
  hugo --minify --cleanDestinationDir --destination "${REPO_ROOT}/.build/site" "$@"
}

run_whimsy_checks() {
  cd "${REPO_ROOT}/.build/site"
  python3 -m http.server 8000 &
  SERVER_PID=$!
  sleep 1
  ruby "${REPO_ROOT}/scripts/run_whimsy_checks.rb" http://127.0.0.1:8000
  kill $SERVER_PID
}

run_checks() {
  python3 "${REPO_ROOT}/scripts/check_internal_links.py" --site-root "${REPO_ROOT}/.build/site"
  run_whimsy_checks
}

run_tests() {
  ruby "${REPO_ROOT}/scripts/test_run_whimsy_checks.rb"
}

generate_docs() {
  python3 "${REPO_ROOT}/scripts/generate_docs.py" "$@"
}

serve_site() {
  cd "${SITE_SRC_DIR}"
  hugo server --bind 0.0.0.0 --baseURL "http://localhost:1313" --buildDrafts --disableFastRender "$@"
}

main() {
  local cmd="${1:-}"
  if [[ -z "${cmd}" ]]; then
    usage
    exit 2
  fi
  shift || true

  resolve_paths

  case "${cmd}" in
    build)
      build_site "$@"
      run_checks
      ;;
    check)
      run_checks
      ;;
    docs)
      generate_docs "$@"
      ;;
    test)
      run_tests
      ;;
    serve)
      serve_site "$@"
      ;;
    shell)
      exec bash
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
