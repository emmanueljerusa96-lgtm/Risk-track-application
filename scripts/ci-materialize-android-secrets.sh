#!/usr/bin/env bash
# Writes gitignored Android credentials from GitHub Actions secrets.
# Never prints secret values.
set -euo pipefail

if [ -z "${GOOGLE_SERVICES_JSON:-}" ]; then
  echo "Missing repository secret GOOGLE_SERVICES_JSON." >&2
  echo "Set it to the contents of android/app/google-services.json (package com.risktrack.app)." >&2
  exit 1
fi

mkdir -p android/app
printf '%s' "$GOOGLE_SERVICES_JSON" > android/app/google-services.json

python3 - <<'PY'
import base64
import json
import pathlib
import sys

path = pathlib.Path("android/app/google-services.json")
raw = path.read_bytes().strip()
if not raw.startswith(b"{"):
    try:
        raw = base64.b64decode(raw, validate=False)
    except Exception as error:
        sys.exit(f"GOOGLE_SERVICES_JSON is neither JSON nor base64: {error}")
    path.write_bytes(raw if raw.endswith(b"\n") else raw + b"\n")

try:
    data = json.loads(path.read_text(encoding="utf-8"))
except json.JSONDecodeError as error:
    sys.exit(f"GOOGLE_SERVICES_JSON is not valid JSON: {error}")

packages = [
    client.get("client_info", {})
    .get("android_client_info", {})
    .get("package_name")
    for client in data.get("client", [])
]
if "com.risktrack.app" not in packages:
    sys.exit(
        "google-services.json package_name must be com.risktrack.app, found: "
        + ", ".join(str(name) for name in packages)
    )
print("Firebase config matches package com.risktrack.app.")
PY

signing_names=(
  ANDROID_KEYSTORE_BASE64
  ANDROID_KEYSTORE_PASSWORD
  ANDROID_KEY_ALIAS
  ANDROID_KEY_PASSWORD
)
present=0
for name in "${signing_names[@]}"; do
  if [ -n "${!name:-}" ]; then
    present=$((present + 1))
  fi
done

summary="${GITHUB_STEP_SUMMARY:-}"
note() {
  echo "$1"
  if [ -n "$summary" ]; then
    echo "$1" >> "$summary"
  fi
}

if [ "$present" -eq 0 ]; then
  note "Release keystore secrets are not set. This build uses the debug key and must not be published."
  exit 0
fi

if [ "$present" -ne 4 ]; then
  echo "Set all signing secrets or none of them:" >&2
  printf '  %s\n' "${signing_names[@]}" >&2
  exit 1
fi

mkdir -p android
printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/upload-keystore.jks
umask 077
cat > android/key.properties <<EOF
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyPassword=${ANDROID_KEY_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
storeFile=../upload-keystore.jks
EOF
note "Release upload keystore restored. APK and AAB will be signed with alias ${ANDROID_KEY_ALIAS}."
