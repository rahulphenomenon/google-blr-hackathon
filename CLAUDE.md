# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**tota** is an iOS app (iPhone + iPad) built with SwiftUI. Bundle ID: `com.ramenlabs.tota`.

## Build & Run

```bash
# Build (debug)
xcodebuild -project tota/tota.xcodeproj -scheme tota -configuration Debug -sdk iphonesimulator build

# Build (release)
xcodebuild -project tota/tota.xcodeproj -scheme tota -configuration Release -sdk iphoneos build

# Run tests (when test targets are added)
xcodebuild -project tota/tota.xcodeproj -scheme tota -sdk iphonesimulator test
```

The project is best developed in Xcode (`open tota/tota.xcodeproj`).



## Swift Configuration

- Swift 5.0 with **Swift Approachable Concurrency** enabled
- Default actor isolation: `MainActor`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` enabled
- Deployment target: iOS 26
- Xcode 26.2

## Notes

- The `.gitignore` is configured for Swift, Xcode, and Firebase — Firebase integration may be planned
- All new Swift files should be placed under `tota/tota/` to be picked up by Xcode's file system synchronization (PBXFileSystemSynchronizedRootGroup)
