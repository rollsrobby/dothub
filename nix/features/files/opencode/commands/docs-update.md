---
description: Update the local reference repositories to their configured upstream branches
agent: build
---

# Update reference repositories

1. Read the repository registry in the sibling `docs-setup.md` file (installed at `~/.config/opencode/commands/docs-setup.md`). Use that table as the single source of repository URLs, branches, and directory names.
2. Check that Git and `git subtree` are available, and that `~/.coding-agent` is the exact repository root, has a HEAD commit, and has a clean working tree, including untracked files. If setup is missing or incomplete, ask the user to run `/docs-setup`. If there are local changes, explain them and ask how to proceed while preserving those changes.
3. Preflight every registry path: it must exist and have Git subtree history in this repository. If any is missing or is an ordinary directory or nested clone, stop and explain which paths need setup or reconciliation before updating anything.
4. From `~/.coding-agent`, update each registry entry in order with `git subtree pull --prefix repos/<directory> <repository> <branch> --squash`. Use the HTTPS URLs from the registry. Before each pull, confirm the working tree is still clean.
5. On any failure or conflict, stop and report the error and current Git state. Preserve local changes and completed updates, and ask the user how to proceed.
6. Report which repositories were updated, already current, or failed. Complete only when all six registry entries have been processed successfully, or clearly report where the operation stopped.
