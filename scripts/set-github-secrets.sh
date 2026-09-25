#!/usr/bin/env bash
# Uploads local Android credentials to GitHub Actions secrets.
# Does not print secret values. Requires gh auth with secrets permission.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
repo=${GITHUB_REPOSITORY:-emmanueljerusa96-lgtm/Risk-track-application}

json=android/app/google-services.json
if [ ! -f "$json" ]; then
  echo "Missing $json. Place the Firebase file there before setting secrets." >&2
  exit 1
fi

python3 - "$json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
packages = [
    client.get("client_info", {}).get("android_client_info", {}).get("package_name")
    for client in data.get("client", [])
]
if "com.risktrack.app" not in packages:
    sys.exit("Refusing to upload google-services.json: package_name is not com.risktrack.app")
PY

gh secret set GOOGLE_SERVICES_JSON --repo "$repo" < "$json"
echo "Set GOOGLE_SERVICES_JSON on $repo"

props=android/key.properties
if [ ! -f "$props" ]; then
  echo "android/key.properties is missing, so signing secrets were not set."
  echo "Create android/upload-keystore.jks, copy android/key.properties.example to android/key.properties, then rerun this script."
  exit 0
fi

read_prop() {
  local key=$1
  local value
  value=$(grep -E "^${key}=" "$props" | head -n 1 | cut -d= -f2- | tr -d '\r')
  if [ -z "$value" ] || [ "$value" = "CHANGE_ME" ]; then
    echo "android/key.properties is missing a real $key." >&2
    exit 1
  fi
  printf '%s' "$value"
}

store_password=$(read_prop storePassword)
key_password=$(read_prop keyPassword)
key_alias=$(read_prop keyAlias)
store_file=$(read_prop storeFile)
keystore=$(python3 -c 'import os,sys; print(os.path.normpath(sys.argv[1]))' "android/app/$store_file")
if [ ! -f "$keystore" ]; then
  echo "Keystore not found at $keystore (from storeFile=$store_file)." >&2
  exit 1
fi

base64 < "$keystore" | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$repo"
printf '%s' "$store_password" | gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$repo"
printf '%s' "$key_password" | gh secret set ANDROID_KEY_PASSWORD --repo "$repo"
printf '%s' "$key_alias" | gh secret set ANDROID_KEY_ALIAS --repo "$repo"
echo "Set ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD on $repo"
echo "Secret names now on the repository:"
gh secret list --repo "$repo"
