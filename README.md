# Nicotine

![Nicotine hero](Assets/nicotine-hero.png)

Tiny macOS menu bar app that keeps your display awake.

Nicotine lives in the menu bar as a cigarette icon. Click it to pause/resume display wakefulness, toggle launch at login, or quit. No window, no dashboard, no ceremony.

## Install

```sh
brew tap svperior-jon/nicotine
brew trust svperior-jon/nicotine
brew install --cask nicotine
open /Applications/Nicotine.app
```

## Build

```sh
make app
```

## Release

```sh
make notarized-package \
  SIGN_IDENTITY="Developer ID Application: Superior Digital Partners, LLC (W9XJY8C57G)" \
  NOTARY_PROFILE="nicotine-notary"
```
