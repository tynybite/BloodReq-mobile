#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

log() {
  printf '%s\n' "$1"
}

find_nextjs_dir() {
  local candidate
  for candidate in "." "web" "nextjs" "frontend"; do
    local pkg="$candidate/package.json"
    if [[ "$candidate" == "." ]]; then
      pkg="package.json"
    fi

    if [[ -f "$pkg" ]] && grep -q "\"next\"" "$pkg"; then
      if [[ "$candidate" == "." ]]; then
        echo "."
      else
        echo "$candidate"
      fi
      return 0
    fi
  done

  return 1
}

run_flutter_checks() {
  log "Running Flutter quality checks..."
  flutter pub get
  dart format --output=none --set-exit-if-changed .
  flutter analyze --no-pub
  flutter test --no-pub
  flutter build apk --debug --no-pub
}

run_flutter_vulnerability_scan() {
  if [[ "${SKIP_VULN_SCAN:-0}" == "1" ]]; then
    log "Skipping vulnerability scan because SKIP_VULN_SCAN=1"
    return 0
  fi

  if ! command -v trivy >/dev/null 2>&1; then
    log "trivy is required for vulnerability checks. Install: brew install trivy"
    log "Temporary bypass for one commit: SKIP_VULN_SCAN=1 git commit ..."
    return 1
  fi

  log "Running Flutter dependency vulnerability scan..."
  local trivy_log
  trivy_log="$(mktemp)"

  if trivy fs --scanners vuln --pkg-types library --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 . >"$trivy_log" 2>&1; then
    cat "$trivy_log"
    rm -f "$trivy_log"
    return 0
  fi

  cat "$trivy_log"

  # Don't block commits on transient DB/network issues; CI still enforces this gate.
  if grep -q "failed to download vulnerability DB" "$trivy_log" || grep -q "no such host" "$trivy_log"; then
    log "Vulnerability DB is unreachable right now. Skipping local vuln gate for this commit."
    log "CI will run vulnerability checks again."
    rm -f "$trivy_log"
    return 0
  fi

  rm -f "$trivy_log"
  return 1
}

install_node_deps() {
  if [[ -f package-lock.json || -f npm-shrinkwrap.json ]]; then
    npm ci
  elif [[ -f yarn.lock ]]; then
    corepack enable
    yarn install --frozen-lockfile
  elif [[ -f pnpm-lock.yaml ]]; then
    corepack enable
    pnpm install --frozen-lockfile
  else
    npm install
  fi
}

run_nextjs_checks() {
  local next_dir
  next_dir="$1"

  log "Running Next.js quality checks in $next_dir..."
  (
    cd "$next_dir"
    install_node_deps
    npm run lint --if-present
    npm test --if-present
    npm run build --if-present
    npm audit --audit-level=high
  )
}

main() {
  if [[ -f pubspec.yaml ]]; then
    run_flutter_checks
    run_flutter_vulnerability_scan
  fi

  if next_dir="$(find_nextjs_dir)"; then
    run_nextjs_checks "$next_dir"
  fi

  log "All pre-commit checks passed."
}

main "$@"
