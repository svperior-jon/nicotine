# Nicotine

Nicotine is a tiny macOS menu bar app that keeps the display awake.

## Build

```sh
make app
```

The app bundle is created at:

```text
build/Nicotine.app
```

## Run

```sh
make run
```

Nicotine starts with display wakefulness enabled. Use the menu bar item to pause, resume, or quit it.

## Package

```sh
make package
```

This creates:

```text
dist/Nicotine-1.0.0.zip
dist/Nicotine-1.0.0.zip.sha256
```

## Sign

```sh
make signed-package SIGN_IDENTITY="Developer ID Application: Superior Digital Partners, LLC (W9XJY8C57G)"
```

## Notarize

First store Apple notarization credentials in Keychain:

```sh
xcrun notarytool store-credentials "nicotine-notary" \
  --apple-id "YOUR_APPLE_ID_EMAIL" \
  --team-id "W9XJY8C57G" \
  --password "APP_SPECIFIC_PASSWORD"
```

Then build a signed, notarized package:

```sh
make notarized-package \
  SIGN_IDENTITY="Developer ID Application: Superior Digital Partners, LLC (W9XJY8C57G)" \
  NOTARY_PROFILE="nicotine-notary"
```

## Homebrew Cask

The draft cask lives at:

```text
Casks/nicotine.rb
```

To publish it:

1. Create a GitHub release tagged `v1.0.0`.
2. Upload `dist/Nicotine-1.0.0.zip` to that release.
3. Replace the placeholder `sha256` in `Casks/nicotine.rb` with the value from `dist/Nicotine-1.0.0.zip.sha256`.
4. Put `Casks/nicotine.rb` in a Homebrew tap repo, such as `homebrew-nicotine`.

Install from the tap with:

```sh
brew tap svperior-jon/nicotine
brew trust svperior-jon/nicotine
brew install --cask nicotine
```
