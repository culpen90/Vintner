# Vintner

A modern Wine wrapper for macOS built with SwiftUI.

Vintner keeps Wine prefixes organized as bottles, lets you attach a Windows
executable to each bottle, and launches Wine with per-bottle runtime metadata.

## Current shape

- Native SwiftUI macOS app with a sidebar, bottle detail view, activity panel,
  and Settings window.
- Local bottle manifest stored in Application Support.
- Configurable Wine binary path, Esync, Msync, DXVK logging, and Mono/Gecko
  prompt suppression.
- Core command construction and bottle storage covered by tests.

## Run

```sh
swift run Vintner
```

The default Wine path is `/opt/homebrew/bin/wine`. Change it in Settings if
your Wine install lives somewhere else, such as `/usr/local/bin/wine`.

## Test

```sh
swift test
```
