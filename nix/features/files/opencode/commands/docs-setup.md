---
description: Bootstrap the local reference repositories used by documentation commands
agent: build
---

# Set up reference repositories

Populate `~/.coding-agent/repos` with Git subtrees. Run setup only when this command is invoked; configuring Home Manager does not download repositories.

## Repository registry

Use these public HTTPS URLs without requiring GitHub SSH credentials. Keep PnPCore on the existing `master` branch rather than its development default.

| Directory under `repos/` | Repository | Branch |
| --- | --- | --- |
| effect | https://github.com/Effect-TS/effect.git | main |
| pnpcore | https://github.com/pnp/pnpcore.git | master |
| pnpjs | https://github.com/pnp/pnpjs.git | version-4 |
| better-auth | https://github.com/better-auth/better-auth.git | main |
| secretspec | https://github.com/cachix/secretspec.git | main |
| zod | https://github.com/colinhacks/zod.git | main |

## Procedure

1. Check that Git, `git subtree`, and a Git author name and email are available. If anything is missing, ask the user to configure it and stop; preserve their Git settings.
2. Inspect `~/.coding-agent`, including hidden files. If it is absent or empty, create it as needed, run `git init` there, and make an initial empty commit with `git commit --allow-empty -m "Initialize reference repositories"`. If it is nonempty, proceed only when `git rev-parse --show-toplevel` resolves to exactly this directory, it has a HEAD commit, and `git status --porcelain` is empty. Otherwise explain the existing state and ask the user how to proceed. An ancestor repository does not count as this directory's repository.
3. From `~/.coding-agent`, process each registry row in order:
   - If `repos/<directory>` already exists, leave it untouched and report it as skipped. If it is not a Git subtree in this repository's history, flag that it needs manual reconciliation before `/docs-update` can update it.
   - For a missing path, run `git subtree add --prefix repos/<directory> <repository> <branch> --squash`.
   - Before each addition, confirm the working tree is clean. On a failure or conflict, stop and report the error and current state. Preserve local changes and completed additions; ask the user how to proceed.
4. Report which repositories were added, skipped, or failed. Setup is complete when every registry path is present as a subtree; distinguish existing non-subtree paths from successful setup. Mention `/docs-update` for subsequent refreshes.
