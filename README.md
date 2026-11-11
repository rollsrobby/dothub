# dothub

One home for NixOS, nix-darwin, Home Manager, and editable application settings.

## Layout

- `flake.nix` and `flake.lock`: inputs, pinned versions, and the `import-tree` entry point.
- `config/`: native application settings for Neovim, Ghostty, and AeroSpace.
- `nix/features/`: feature-oriented flake-parts modules. System and Home
  Manager definitions for the same feature live together; assets live in `files/`.
- `nix/profiles/`: collections of features and shared system policy.
- `nix/users/rms.nix`: Linux account declaration (groups, shell, SSH keys).
- `nix/hosts/rms-fw/`: Framework system, home profile, hardware, disks, and VM overrides.
- `nix/hosts/rms-lab/`: headless Framework preparation; hardware/install inputs still required.
- `nix/hosts/rms-mbp/`: Apple Silicon Mac system and Home Manager profile.

Each host's `default.nix` connects `home-manager.users.rms` to its own
`home.nix` (`homeModules.rmsFw` or `homeModules.rmsMbp`). Those home profiles
compose shared feature modules and their host-specific sesh lists.

Every `.nix` file under `nix/` is auto-imported as a **flake-parts module**,
not as a NixOS or Home Manager module. Defining a named module does not enable it:
select it through the host/user import lists. Existing `nixosModules` and
`homeModules` exports are retained.

## Editable application configurations

Keep the checkout at `~/dothub` on each host. The Home Manager option
`dotfiles.directory` defaults to `${home.homeDirectory}/dothub/config` and points
to this repository's `config/` directory, not a separate dotfiles checkout.

Both host home profiles import `homeModules.configLinks` for Neovim and Ghostty.
The Mac also links AeroSpace using the same option. Home Manager creates
out-of-store symlinks: edit the files under `config/` directly, without rebuilding
for each application-config change. Applications may still need a reload or restart.

If the checkout lives elsewhere, override the absolute config-directory path in
that host's Home Manager profile:

```nix
# Point editable application links at this checkout's config directory.
dotfiles.directory = "${config.home.homeDirectory}/code/dothub/config";
```

The files are versioned here, but the deployed links use the live checkout rather
than an immutable Nix-store snapshot. A system rollback does not roll back edits
to those files, and moving or deleting the checkout breaks the links until they
are updated. Application installation remains platform-specific. The VM disables
these links because it does not share the host checkout.

## Hardware identifiers

The Framework disk configuration uses `/dev/disk/by-path/pci-0000:02:00.0-nvme-1`
instead of a drive serial number. It identifies the internal NVMe connection;
verify its target before running Disko, especially after hardware or firmware
changes. Never assume a changed path still identifies the disk you intend to erase.

The Unicorne keyboard uses the udev alias `/dev/input/boardsource-unicorne`.
The rule in `nix/features/keyboard.nix` matches public vendor/product IDs and
the main keyboard interface, not a serial number or USB topology, so it works
across USB ports and docks. The alias supports one matching Unicorne at a time;
two identical keyboards would need a different selection strategy. The built-in
keyboard keeps its existing platform path.

## Check changes without activating them

Keep build outputs (`result`, `result-*`), VM disks (`*.qcow2`), Finder metadata
(`.DS_Store`), and application backups out of Git; add appropriate `.gitignore`
rules before importing files or building in the checkout.

```sh
# Review new files before including them; never add secrets or generated state.
git status --short --untracked-files=all
# Make reviewed source files visible to flake evaluation without committing them.
git add -N -- flake.nix nix config README.md

# Format Nix files, then evaluate all checks without building them.
nix fmt
nix flake check --no-build

# Build the laptop configuration, without switching to it.
nix build .#nixosConfigurations.rms-fw.config.system.build.toplevel
```

`nix flake check` without `--no-build` builds formatting, system, Home Manager,
and VM checks. Successful evaluation alone does not prove a build or boot works.

## Test in a VM

```sh
# Build a QEMU runner; no sudo, activation, or real disk partitioning.
nix build .#nixosConfigurations.rms-fw.config.system.build.vm -o result-vm

# Launch from the repo root so the VM disk has a predictable location.
./result-vm/bin/run-rms-fw-vm-vm
```

The script name follows the VM hostname (`rms-fw-vm`) plus `-vm`. Log in as
**rms**, password **vm**, and select Hyprland at the greeter. Sudo is passwordless
inside the VM only. Shut down the VM, rebuild, and rerun to test another change.

The guest has 4 CPUs, 4 GiB RAM, a 20 GiB virtual disk, and a virtual GPU. Its
`rms-fw-vm.qcow2` disk persists between launches: with the VM stopped, delete
that image to reset the guest. NixOS's standard runner shares the host Nix store
read-only, but not your home directory. It uses user-mode networking without
inbound port forwards. This is a config test environment, not a sandbox for
hostile code.

VM-only overrides disable fingerprint/lid scripts, hardware maintenance,
Bluetooth, nested libvirt, SSH serving, and Tailscale/Rex serving. Dotfile symlinks
are disabled because the host checkout is not shared. Hardware-specific behavior
and authenticated applications still need testing on the laptop. Wayland graphics
in QEMU can behave differently from the real AMD GPU.

Don't use `build-vm-with-bootloader` to test this setup: the normal VM build is
intended to test configuration and desktop behavior, not the physical disk layout.


### ReGreet styling and monitor layout

The laptop and VM use the same ReGreet configuration in
`nix/features/greeter.nix`, with CSS in
`nix/features/files/regreet/style.css`: a neutral charcoal background,
wider centered login panel, and readable controls. The experimental SDDM themes
have been removed. `nix build .#vm -o result-vm` is a short alias for the VM build.

Cage now uses `-m last`, as recommended by ReGreet. Its default `extend` mode
centers the application over the combined monitor canvas, which can leave the
form off-center on an external display when the laptop panel is still enabled.
The `greeter` check exercises both modes with two virtual outputs and checks
that the host and VM keep the same output policy and login PAM integration.

**Important:** `last` means the last connected/enumerated output, not necessarily
an external display. It handles connection/disconnection but is not lid-aware.
Test cold boot and restart with the real dock and lid closed before switching.
If firmware/DRM enumeration selects the closed internal panel, deterministic
lid-aware output selection will need a compositor policy rather than more CSS.
The VM cannot validate your physical dock's enumeration order.

Authentication is unchanged: greetd uses the `login` PAM stack, including the
laptop's existing fingerprint configuration. ReGreet starts authentication after
Login and displays PAM instructions. The reader remains disabled by the existing
lid handler when closed. The VM has no reader and continues to use `rms` / `vm`.
Styling changes are shared with the laptop configuration, but building/testing
them does not activate them on the running system.

## OpenCode web UI over Tailscale

`nix/features/opencode-server.nix` runs OpenCode V2 as `rms` at
`127.0.0.1:4096`, using the existing home directory, provider credentials, and
configuration. A **separate** userspace Tailscale daemon gives it its own node
identity without changing `rms-fw` or its existing Tailscale connection. Neither
HTTP nor HTTPS needs a host firewall opening; this does not enable Funnel.

After building/checking the configuration, activate it and enroll the new node:

```sh
# Activate on the laptop (not in the test VM).
sudo nixos-rebuild switch --flake .#rms-fw

# Follow the login URL; state persists across boots. No auth key goes in Nix.
sudo tailscale --socket=/run/tailscale-opencode/tailscaled.sock up \
  --hostname=opencode --accept-dns=false --accept-routes=false

# Stop automatic retries while approving HTTPS interactively.
sudo systemctl stop opencode-serve
# Enable/approve HTTPS when prompted, then press Ctrl+C after it starts serving.
sudo tailscale --socket=/run/tailscale-opencode/tailscaled.sock serve \
  --https=443 http://127.0.0.1:4096
sudo systemctl start opencode-serve
```

Enable MagicDNS and HTTPS certificates in the Tailscale admin console if they
aren't enabled already. With the node name `opencode` available in the
`tailscalename.ts.net` tailnet, open **https://opencode.tailscalename.ts.net** from a
Tailscale-connected device. If another node already owns that name, resolve the
collision in the admin console. The new node is subject to your tailnet ACLs;
restrict TCP 443 to your own identity/devices. HTTPS certificate names are public
in certificate transparency logs, but the service itself remains tailnet-only.

OpenCode additionally requires authentication. Retrieve its generated password
locally (never commit it); the Basic-auth username, if requested, is `opencode`:

```sh
# Password persists across service restarts, stored mode 0600 outside the Nix store.
sudo -u rms cat /var/lib/opencode-server/password

# Optional: connect the terminal client to this same server.
OPENCODE_PASSWORD="$(cat /var/lib/opencode-server/password)" \
  opencode --server http://127.0.0.1:4096

# Inspect the three independent services.
systemctl status opencode-server tailscale-opencode opencode-serve
```

The normal CLI's managed background service is separate. This server runs with
`rms`'s filesystem and command-execution privileges, so only grant access to
trusted users. Shell-only environment variables and unlocked interactive secret
stores aren't automatically inherited by the system service. Provider credentials
must be available to the server user. The server and dedicated Tailscale daemon
are both disabled in `build-vm`; closing/suspending the laptop also makes the web
UI unavailable.

## Headless Framework: rms-lab (preparation only)

`nix/hosts/rms-lab/` composes shared CLI, Fish/Zsh, Neovim, tmux/sesh,
OpenCode CLI/config, and a personal Home Manager Rex service as `rms` with linger.
It does not import the laptop, desktop, or VM profiles. Rex derives its node name
from the host: `rex-rms-lab`; the laptop remains `rex-rms-fw`. OpenCode on `rms-fw`
continues unchanged until a separate migration.

**This is not an installable system yet.** `hardware.nix` intentionally fails an
assertion, and supplies no root filesystem or bootloader. Before deployment:

- Confirm the exact Framework model/CPU and architecture (currently a provisional
  `x86_64-linux` target), firmware mode, NICs, and desired storage/encryption layout.
- Generate hardware configuration on the target, then place its NixOS settings
  inside `flake.nixosModules.rmsLabHardware` in `hardware.nix`. Every `.nix` file
  under `nix/` is a flake-parts module: do not drop a raw generated module there.
  Supply verified filesystems/UUIDs, initrd drivers, swap and bootloader settings,
  and the matching nixos-hardware profile if appropriate. Remove the blocking
  assertion only after review. There is no lab Disko configuration; do not use
  the laptop's device path or partitioning configuration.
- Provision a local `rms` password for console/sudo recovery securely during
  installation. The shared account includes the existing mobile-phone public
  admin SSH key; no private keys, host keys or passwords are copied. SSH accepts
  keys only and is opened only on `tailscale0`. Plan console access for initial
  network and Tailscale enrollment. NetworkManager/DHCP is configured; supply any
  Wi-Fi, static addressing or other site-specific inputs separately.
- Put this checkout at **`/home/rms/dothub`**, owned by `rms`, before using Neovim
  or the dothub sesh entry. Neovim uses the shared editable config link, not a
  store snapshot; Ghostty is not linked/installed on the lab. Lazy.nvim/plugins
  and language tools may need first-run network access. Shared tmux's explicit
  yank binding uses `wl-copy` (requires Wayland); headless client clipboard
  integration needs terminal support rather than a local desktop clipboard.
- Enroll the host Tailscale node and the personal Rex node independently using
  the normal interactive login flows. Rex retains its default personal-access
  restrictions (`allowTailnetMembers = false`, no anonymous access). Enroll the
  dedicated OpenCode node with **`--hostname=opencode-rms-lab`**, using the same
  socket and HTTPS Serve steps above on the lab. Do not reuse the laptop's
  `opencode` node identity/state. Its URL is then
  `https://opencode-rms-lab.<tailnet>.ts.net`; restrict access with tailnet ACLs.
- Authenticate Rex/package access, OpenCode providers/MCP, GitHub and other CLI
  tools as needed on the new host. Supply any private Nix registry/cache netrc
  outside Git/the Nix store if required; no laptop `/etc/nix/netrc` is assumed.
  Generate/provision the lab's own SSH signing key (shared Git settings expect
  `~/.ssh/id_ed25519.pub`). The lab does not assume a 1Password desktop agent.

OpenCode uses the existing loopback-only authenticated service at `127.0.0.1:4096`
and a separate userspace Tailscale HTTPS proxy. Its password is generated locally
in `/var/lib/opencode-server/password`; neither service exposes a public port or
enables Funnel. Credentials and Tailscale state must be created on the new host.

Preparation checks, without activation:

```sh
nix eval .#nixosConfigurations.rms-lab.config.networking.hostName
nix build .#nixosConfigurations.rms-lab.config.home-manager.users.rms.home.activationPackage --no-link
# Only after supplying and reviewing real hardware/install settings:
nix build .#nixosConfigurations.rms-lab.config.system.build.toplevel --no-link
```

The flake exports `checks.x86_64-linux.rms-lab-home`, but deliberately no lab
toplevel check until real hardware is supplied. `nix flake check --no-build` also
evaluates every `nixosConfigurations` toplevel, so the lab's intentional hardware
assertion blocks that aggregate command until provisioning is completed; use the
targeted home build above in the meantime. A successful home build does not
validate boot, hardware, remote enrollment, credentials or application first-run
downloads. No deployment or activation is performed by these checks.

## MacBook: rms-mbp

`nix/hosts/rms-mbp/default.nix` assembles nix-darwin, Home Manager,
mac-app-util, and nix-homebrew. `system.nix` preserves the supplied macOS defaults,
Touch ID for sudo, UID 501, and `system.stateVersion = 5`.
`home.nix` preserves `home.stateVersion = "25.05"` and the editable dotfile links;
`nix/features/cli.nix` configures the shared CLI;
`nix/features/mac-cli-packages.nix` adds the Mac's package selections.
`nix/features/mac-applications.nix` owns Aerospace, IINA, and VS Code via
Home Manager, including mac-app-util integration for user applications. Its
Darwin module also owns Homebrew taps, brews, and casks; the host keeps
nix-homebrew installation and integration settings.
The Linux desktop profile is deliberately not imported on the Mac.

On the Mac, from a checkout of this repository:

```sh
# Build without changing the running Mac first; inspect any warnings.
darwin-rebuild build --flake .#rms-mbp

# Activate only after the build succeeds and the configuration is reviewed.
sudo darwin-rebuild switch --flake .#rms-mbp
```

Keep this repository at `/Users/rms/dothub` (or override `dotfiles.directory`
as described above). AeroSpace, Neovim, and Ghostty link to its `config/` directory;
no separate dotfiles checkout is required. Tmux and sesh are managed directly by
Home Manager. The legacy `.config/nix-darwin` link is no longer declared; use this
repository's root flake for both build and switch commands.
Back up unmanaged dotfiles before the first Home Manager activation if they
conflict with the declared links.

The main Mac packages now use this repository's locked `nixpkgs` and Home Manager
inputs. This is a package-version change relative to the old Mac flake's lock,
which wasn't supplied. Homebrew installation and cask availability need checking
on the Mac; a Linux evaluation cannot validate them or run macOS activation.
`checks.rms-mbp-evaluation` evaluates the Mac system and Home Manager derivations
on Linux without trying to build them. The root `systems` list remains Linux-only
for the existing platform-specific `perSystem` packages; it does not restrict
`darwinConfigurations.rms-mbp`.

## Shared CLI configuration

Both hosts import `homeModules.cli` from `nix/features/cli.nix`. It owns
portable CLI program settings, common aliases, `EDITOR`, and `PAGER`.
Aliases and variables use Home Manager's `home.shellAliases` and
`home.sessionVariables`, so Fish inherits them directly rather than copying Zsh
configuration.

CLI behavior now uses the Linux setup as the baseline on both platforms:
Atuin and its history bindings, Git identity/SSH signing, GitHub extensions,
fzf behavior, gh-dash bindings, the worktree helper, devenv hook, and Zsh/sesh
startup are all defined once in `cli.nix`. The Mac profile separately imports
`homeModules.macCliPackages` from `mac-cli-packages.nix` for its package selections.
That module now contains only the Mac's Docker/Colima backend, native-process
compatibility bundle, and 1Password CLI integration exception. OS-specific desktop
settings remain platform-local; editable application settings live under this
repository's `config/` directory.

The stale Mac git-spice completion hook, REX PATH override, `azs`/`w` aliases,
and fzf/GitHub overrides have been removed. The `gs` alias means `gh stack` on
both machines; the Mac's installed `git-spice` is still available by its full name.
The gh-dash PR binding is a list, matching the application's configuration schema.

**Before committing on the Mac:** shared Git settings enable SSH signing using
`~/.ssh/id_ed25519.pub`. Ensure that Mac's matching private key is available
locally or through its SSH agent. Keys are not copied between machines.

`checks.cli` checks Linux/Mac parity, Fish/Zsh alias isolation, and the generated
Fish environment. The Mac configuration is evaluated on Linux, but Mac binaries
and activation still need testing on the Mac.


## Sharing follow-ups

Keep this queue here so it survives individual development sessions:

- [x] CLI package selections: shared portable tools, with module-owned binaries
  deduplicated and container/process/1Password exceptions kept platform-local.
- [x] Tmux and sesh: shared behavior, per-host sessions, and platform-specific
  clipboard commands (macOS pbcopy / Linux Wayland wl-copy).
- [x] Starship: shared prompt settings expressed directly in Nix/Home Manager.
- [x] Neovim and Ghostty links: shared `configLinks` declarations using `home.homeDirectory`.
- [x] Nix policy: shared experimental features and garbage-collection intent,
  adapting platform-specific scheduling options.

Hardware, desktop environments, Homebrew, macOS defaults, home paths, and existing
state versions remain host/platform-specific.

### Shared Starship prompt

Edit `programs.starship.settings` directly in `nix/features/starship.nix`
to change both prompts. Home Manager generates the TOML and validates it against
the schema supplied by the configured Starship package. There is no separate
versioned TOML file or external Starship symlink. The original dotfiles file is
left untouched, but is no longer a source for either managed profile.

The prompt retains the existing arrows, Git status counts/colors, automatic
language detection, and Docker/Kubernetes context. Improvements include brighter
untracked-file counts, divergence counts, abbreviated long paths, omission of
package-version clutter, and command durations for commands taking at least
three seconds. Kubernetes context remains visible when configured; it is not
restricted to particular project directories.

Home Manager manages Zsh integration on both machines and Fish on Linux. The
`starship` check compares generated TOML with the Nix settings and exercises real
prompt rendering: success/error characters, command durations, Git divergence,
stash counts, path truncation, and package visibility. The Mac configuration is
evaluated; its actual shell still needs testing on the Mac.


### Shared CLI package ownership

`nix/features/cli.nix` owns the portable developer-tool selection for both
hosts: editors/language servers, Nix tooling, Cargo, Azurite, Git tooling,
archives/YAML tools, Ollama, and terminal/session utilities. These are user-profile
packages, not Linux system-global installs. Enabled Home Manager programs install
their own binaries; do not repeat them in plain `home.packages` lists.

Tmux and sesh are enabled by the shared CLI profile. Lazygit still uses a fallback
package when its Home Manager module is disabled on the Mac. Theme runtime tools
are provided by the theme derivation rather than added to the user's package bag.

Platform exceptions remain explicit:

- Mac Docker CLI and Colima stay in `mac-cli-packages.nix`. Linux keeps Podman's
  docker-compatible command; this change does not enable Docker or a new socket.
- Linux's core system owns process tools. The Mac keeps nixpkgs' Darwin `procps`
  compatibility bundle; it is not Linux procps-ng and does not promise GNU flags.
- Linux's dedicated 1Password modules own CLI/GUI packages and integration.
  The Mac keeps its own CLI package alongside the existing app installation.

The shared Ollama selection installs its CLI/default runtime only. It does not
start a daemon, download models, or enable CUDA/ROCm. GPU/server choices remain
host-specific. Newly shared Mac developer tools also become available on Linux;
Linux's Nix/editor/review tools become available on the Mac.

`checks.cli-packages` verifies presence on both platforms, unique direct package
ownership, and the container/configuration exceptions. Mac checks evaluate the
configuration without trying to build Darwin packages on Linux.


### Shared tmux and client-specific sesh

`nix/features/tmux.nix` owns the common tmux configuration; clipboard copying
uses `/usr/bin/pbcopy` on macOS and Nix's `wl-copy` on Linux. Prefix is `Ctrl-a`:
`o` selects a sesh session, `L` returns to the last session, and `g` opens lazygit.
The theme is pinned to an immutable revision, uses Nix runtime utilities instead
of Homebrew discovery, and never automatically fetches Git remotes. Optional
web-Git and music widgets are disabled.

`nix/features/sesh.nix` owns integration, not paths. Edit each client's list in:

- Linux: `nix/hosts/rms-fw/sesh.nix` (`~/c`, `~/utils/dbui`, `~/docs/notes`).
- Mac: `nix/hosts/rms-mbp/sesh.nix` (`~/code`, `~/tools/dbui`).

Both derive absolute paths from `home.homeDirectory`. Session entries keep their
own checkout paths and editor commands; when migrating them, replace old
`~/nix-config` targets with `~/dothub` and use `nix/` paths for source files.
Before first activation on the Mac, back up/move existing
`~/.config/tmux` and `~/.config/sesh` links or directories if Home Manager reports
conflicts; do not edit generated files or delete the original dotfiles checkout.

`checks.tmux-sesh` checks client paths, clipboard selection, generated sesh TOML,
and the Linux tmux configuration using an isolated temporary server. Darwin is
evaluated here; its runtime clipboard behavior must be tested on the Mac.


### Shared Nix policy

`nix/features/nix.nix` provides `nixosModules.nixPolicy` and
`darwinModules.nixPolicy`. Both enable `nix-command`/`flakes` and automatic weekly
GC with `--delete-older-than 30d`. Linux imports it through `profiles/base.nix`
and retains its persistent systemd timer; the Mac imports it in its system
profile and uses launchd on Sundays at 03:15 local time. This enables scheduled
GC on the Mac after activation; no collector is run by editing or building here.

GC removes old generations and then unreachable store paths; it does not delete
project files or active/rooted store paths. Older rollback generations may no
longer be available. Linux's `persistent` option is not passed to nix-darwin.
