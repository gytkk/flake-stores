# flake-stores

This repository is a frozen archive of the non-nixpkgs app packages formerly consumed by `gytkk/nix-flakes`.

> [!IMPORTANT]
> Active package definitions, manual update scripts, and read-only CI moved to [`gytkk/nix-flakes/packages/apps`](https://github.com/gytkk/nix-flakes/tree/08dc4ea315de58ee6f6cc9892dae56d799a298f1/packages/apps) in [`08dc4ea`](https://github.com/gytkk/nix-flakes/commit/08dc4ea315de58ee6f6cc9892dae56d799a298f1). Make future package changes there.

The source and history remain here for reference. This repository no longer runs CI or automated package updates.

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
│   ├── herdr
│   │   ├── package.nix
│   │   └── update.sh
│   ├── kimi-code
│   │   ├── package.nix
│   │   └── update.sh
│   ├── opencode
│   │   ├── package.nix
│   │   └── update.sh
│   └── pi
│       ├── package.nix
│       └── update.sh
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
| agent-browser | 0.35.1 |
| claude-code | 2.1.251 |
| codex | 0.151.0 |
| herdr | 0.8.2 |
| kimi-code | 0.39.1 |
| opencode | 1.18.25 |
| pi | 0.84.4 |

## Build entrypoints

- `nix build .#packages.<system>.opencode`
- `nix build .#packages.<system>.default` (same as first app)
- `nix run .#apps.<system>.opencode`

## Maintenance status

This snapshot remains buildable for historical reference, but it is not maintained. Use the `packages/apps` catalog in `gytkk/nix-flakes` for builds, updates, and new packages.
