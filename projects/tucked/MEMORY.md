# Tucked Project Memory

## Project
Couples messaging app with widget-based "post-it note" communication. Expo + pnpm monorepo.

## Key Learnings

### Android Build (Glance Widgets)
- `LocalContext.current` causes Kotlin backend compiler crash in Glance `@Composable` functions - never use it
- ColorProvider requires `ColorProvider(day = Color(...), night = Color(...))` - two params, not one
- Always validate Kotlin locally first: `./gradlew :widget-bridge:compileDebugKotlin` (~5 min vs ~20 min EAS)
- Widget click actions were removed and need to be re-added with proper Glance pattern (not using LocalContext)

### Metro / pnpm Monorepo
- `unstable_enableSymlinks = true` is a NO-OP in Metro - symlinks are always followed via FileSystemLookup
- `disableHierarchicalLookup = true` can BREAK pnpm resolution - prevents Metro from finding modules in .pnpm store
- `getDefaultConfig()` from `expo/metro-config` auto-detects pnpm monorepos via `pnpm-workspace.yaml`
- Simplified metro.config.js (watchFolders + nodeModulesPaths only) - not yet tested as of 2026-02-06
- See [metro-pnpm.md](metro-pnpm.md) for detailed notes

### Environment
- Windows 11 + WSL2, project on `/mnt/c/` (slow I/O)
- ADB keys shared: `cp /mnt/c/Users/npark/.android/adbkey ~/.android/adbkey`
- ADB reverse: `adb reverse tcp:8081 tcp:8081` for Metro connection
- `REACT_NATIVE_PACKAGER_HOSTNAME=127.0.0.1` needed for emulator
- Watchman NOT installed in WSL (would improve Metro perf)
- No iOS dev (2012 MacBook too old)

### Git
- 4+ commits ahead of origin/main (not pushed as of 2026-02-06)
- SSH auth, user: nparkison, no Co-Authored-By attribution
