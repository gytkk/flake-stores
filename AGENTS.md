# AGENTS.md

## README App Versions Sync

Whenever a `package.nix` version changes (added, updated, or removed), update the
**App versions** table in `README.md` to match.

How to read versions:

```bash
grep 'version = ' apps/*/package.nix
```

The table format in `README.md`:

```markdown
| App | Version |
|-----|---------|
| <app-name> | <version> |
```

Rules:
- One row per app directory under `apps/`.
- Sort rows alphabetically by app name.
- Version string must exactly match the `version = "..."` value in `package.nix`.
