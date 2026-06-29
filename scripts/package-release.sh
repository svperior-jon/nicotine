#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="Nicotine"
APP_DIR="build/${APP_NAME}.app"
DIST_DIR="dist"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.zip"
SHA_PATH="${ZIP_PATH}.sha256"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Missing ${APP_DIR}. Run make app first." >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

ditto -c -k --norsrc --noextattr --keepParent "${APP_DIR}" "${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}" | tee "${SHA_PATH}"

echo
echo "Packaged ${ZIP_PATH}"
echo "Checksum written to ${SHA_PATH}"
