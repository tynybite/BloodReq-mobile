#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_PROPERTIES="$ROOT_DIR/android/local.properties"

if [[ ! -f "$LOCAL_PROPERTIES" ]]; then
  echo "Missing $LOCAL_PROPERTIES"
  exit 1
fi

sdk_dir="$(awk -F= '/^sdk\.dir=/{print $2}' "$LOCAL_PROPERTIES" | sed 's#\\: #:#g; s#\\:#:#g')"
if [[ -z "${sdk_dir:-}" || ! -d "$sdk_dir" ]]; then
  echo "Android SDK not found. Check sdk.dir in $LOCAL_PROPERTIES"
  exit 1
fi

zipalign_bin="$(find "$sdk_dir/build-tools" -type f -name zipalign 2>/dev/null | sort -V | tail -n 1)"
readobj_bin="$(find "$sdk_dir/ndk" -type f -name llvm-readobj 2>/dev/null | sort -V | tail -n 1)"

if [[ -z "${zipalign_bin:-}" || ! -x "$zipalign_bin" ]]; then
  echo "zipalign not found in Android SDK build-tools"
  exit 1
fi

if [[ -z "${readobj_bin:-}" || ! -x "$readobj_bin" ]]; then
  echo "llvm-readobj not found in Android SDK NDK"
  exit 1
fi

declare -a apks=("$@")
if [[ ${#apks[@]} -eq 0 ]]; then
  for candidate in \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk" \
    "$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
  do
    [[ -f "$candidate" ]] && apks+=("$candidate")
  done
fi

if [[ ${#apks[@]} -eq 0 ]]; then
  echo "No APKs found. Build first, e.g. flutter build apk --release --split-per-abi --target-platform android-arm,android-arm64"
  exit 1
fi

echo "Using zipalign: $zipalign_bin"
echo "Using llvm-readobj: $readobj_bin"
echo

overall_ok=1

check_apk() {
  local apk="$1"
  local tmpdir
  tmpdir="$(mktemp -d)"

  echo "== Checking $(basename "$apk") =="

  if ! "$zipalign_bin" -c -P 16 -v 4 "$apk" >/dev/null; then
    echo "  [FAIL] zipalign -P 16 check failed"
    overall_ok=0
  else
    echo "  [OK] zip alignment for 16 KB pages"
  fi

  local so_list
  so_list="$(unzip -Z1 "$apk" | awk '/^lib\/.*\.so$/')"
  if [[ -z "$so_list" ]]; then
    echo "  [WARN] no native .so libraries found"
    rm -rf "$tmpdir"
    return
  fi

  while IFS= read -r so; do
    [[ -z "$so" ]] && continue
    local so_out
    so_out="$tmpdir/$(basename "$so")"
    unzip -p "$apk" "$so" > "$so_out"

    local min_align
    min_align="$("$readobj_bin" --program-headers "$so_out" | awk '/Type: PT_LOAD/{inload=1} inload && /Alignment:/{print $2; inload=0}' | sort -n | head -n 1)"

    if [[ -z "${min_align:-}" ]]; then
      echo "  [FAIL] $so: could not read PT_LOAD alignment"
      overall_ok=0
      continue
    fi

    if (( min_align < 16384 )); then
      echo "  [FAIL] $so: PT_LOAD min alignment is $min_align (<16384)"
      overall_ok=0
    else
      echo "  [OK] $so: PT_LOAD min alignment is $min_align"
    fi
  done <<< "$so_list"

  rm -rf "$tmpdir"
  echo
}

for apk in "${apks[@]}"; do
  if [[ ! -f "$apk" ]]; then
    echo "Skipping missing APK: $apk"
    continue
  fi
  check_apk "$apk"
done

if (( overall_ok == 1 )); then
  echo "16 KB support checks passed."
  exit 0
fi

echo "16 KB support checks failed."
exit 2
