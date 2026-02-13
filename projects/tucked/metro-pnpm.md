# Metro + pnpm Monorepo Notes

## How pnpm Works with Metro
- pnpm uses symlinks extensively: `apps/mobile/node_modules/react-native` -> `../../../node_modules/.pnpm/react-native@.../node_modules/react-native`
- Each package in `.pnpm` store has its own `node_modules/` with symlinks to its dependencies
- Metro's `FileSystemLookup` automatically follows symlinks (no config needed)

## What Works
- `getDefaultConfig(projectRoot)` auto-detects `pnpm-workspace.yaml`
- `watchFolders = [monorepoRoot]` - needed for cross-package imports
- `nodeModulesPaths = [local, root]` - tells Metro where to find modules

## What Doesn't Work
- `unstable_enableSymlinks = true` - no-op, not even in Metro's type definitions
- `disableHierarchicalLookup = true` - breaks pnpm by preventing Metro from walking up from .pnpm store paths

## Minimal Working Config (to verify)
```javascript
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');
const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, '../..');
const config = getDefaultConfig(projectRoot);
config.watchFolders = [monorepoRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(monorepoRoot, 'node_modules'),
];
module.exports = config;
```

## Fallback Options (if above fails)
1. Install watchman in WSL
2. `.npmrc` with `public-hoist-pattern[]=*react*` + `public-hoist-pattern[]=*react-native*`
3. Nuclear: `node-linker=hoisted` + `EXPO_NO_METRO_WORKSPACE_ROOT=1`

## WSL2 Considerations
- `/mnt/c/` has slow I/O - Metro file watching can be sluggish
- `REACT_NATIVE_PACKAGER_HOSTNAME=127.0.0.1` needed for emulator connection
- `adb reverse tcp:8081 tcp:8081` bridges emulator to WSL Metro
