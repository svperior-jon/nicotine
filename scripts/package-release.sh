#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0.0}"
APP_NAME="Nicotine"
APP_DIR="build/${APP_NAME}.app"
DIST_DIR="dist"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.zip"
SHA_PATH="${ZIP_PATH}.sha256"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Missing ${APP_DIR}. Run make app first." >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

if [[ -n "${SIGN_IDENTITY}" ]]; then
  echo "Signing ${APP_DIR}"
  codesign --force --deep --options runtime --timestamp --sign "${SIGN_IDENTITY}" "${APP_DIR}"
  codesign --verify --deep --strict --verbose=2 "${APP_DIR}"
  spctl --assess --type execute --verbose=2 "${APP_DIR}" || true
fi

ditto -c -k --norsrc --noextattr --keepParent "${APP_DIR}" "${ZIP_PATH}"

if [[ -n "${NOTARY_PROFILE}" ]]; then
  echo "Submitting ${ZIP_PATH} for notarization"
  xcrun notarytool submit "${ZIP_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
  xcrun stapler staple "${APP_DIR}"
  xcrun stapler validate "${APP_DIR}"

  rm -f "${ZIP_PATH}"
  ditto -c -k --norsrc --noextattr --keepParent "${APP_DIR}" "${ZIP_PATH}"
fi

shasum -a 256 "${ZIP_PATH}" | tee "${SHA_PATH}"

echo
echo "Packaged ${ZIP_PATH}"
echo "Checksum written to ${SHA_PATH}"
