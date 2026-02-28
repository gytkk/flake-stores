# flake-stores

Monorepo for non-nixpkgs app packages consumed by `gytkk/nix-flakes`.

## Layout

```
.
├── apps
│   ├── agent-browser
│   │   ├── package.nix
│   │   └── update.sh
│   ├── claude-code
│   │   ├── package.nix
│   │   └── update.sh
│   ├── codex
│   │   ├── package.nix
│   │   └── update.sh
│   └── opencode
│       ├── package.nix
│       └── update.sh
├── .github/workflows
│   ├── ci.yml
│   └── update.yml
├── flake.nix
├── scripts
│   ├── sync-readme-versions.sh
│   └── update-all.sh
├── settings.json
└── README.md
```

## App versions

| App | Version |
|-----|---------|
| agent-browser | 0.15.1 |
| claude-code | 2.1.63 |
| codex | 0.106.0 |
| opencode | 1.2.9 |

## Build entrypoints

- `nix build .#packages.<system>.opencode`
- `nix build .#packages.<system>.default` (same as first app)
- `nix run .#apps.<system>.opencode`

## Adding new apps

To add a new app package:

1. Create `apps/<app-name>/package.nix`.
2. Use `callPackage` arguments available from nixpkgs (`stdenvNoCC`, `fetchzip`, etc.).
3. Ensure the package path creates a `meta.mainProgram` if the package should be run via `nix run`.
4. Add `apps/<app-name>/update.sh` if you want automatic version updates.
5. Optionally export additional metadata files later if needed.

To disable automatic updates for an app, add its name to the `update.deny` list in `settings.json`.

The flake discovers app directories automatically, so no extra flake changes are required.

## CI behavior

- **CI**: changed-app build matrix for `pull_request`, `push`, and manual runs.
- **Update workflow**: runs every 3 hours, on push, and manual trigger; updates all app update scripts that exist, builds changed packages, and commits updates.
