{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      linux = self.nixosConfigurations.rms-fw.config.home-manager.users.rms;
      mac = self.darwinConfigurations.rms-mbp.config.home-manager.users.rms;
      sessions = home: home.programs.sesh.settings.session;
      session =
        home: name:
        lib.findFirst (s: s.name == name) (throw "Missing sesh session: ${name}") (sessions home);
      tmuxConfig = home: home.xdg.configFile."tmux/tmux.conf".text;
      expected = pkgs.writeText "linux-sesh.json" (builtins.toJSON linux.programs.sesh.settings);
    in
    {
      checks.tmux-sesh =
        assert lib.all (home: home.programs.tmux.enable && home.programs.sesh.enable) [
          linux
          mac
        ];
        assert lib.all (home: home.programs.sesh.zoxidePackage == null) [
          linux
          mac
        ];
        assert (session linux "nix-config").path == "/home/rms/nix-config";
        assert (session linux "sml dev").path == "/home/rms/c/sml/dev";
        assert (session mac "sml dev").path == "/Users/rms/code/sml/dev";
        assert (session mac "Database").path == "/Users/rms/tools/dbui";
        assert (session linux "Database").path == "/home/rms/utils/dbui";
        assert (session mac "tmux").startup_command == "nvim modules/features/tmux.nix";
        assert (session mac "sesh").startup_command == "nvim modules/hosts/rms-mbp/sesh.nix";
        assert lib.all (name: (session mac name).path == "/Users/rms/nix-config") [
          "tmux"
          "sesh"
          "nix-darwin"
        ];
        assert builtins.length (sessions linux) == 11 && builtins.length (sessions mac) == 18;
        assert lib.hasInfix "/usr/bin/pbcopy" (tmuxConfig mac);
        assert !(lib.hasInfix "wl-copy" (tmuxConfig mac));
        assert lib.hasInfix "wl-copy" (tmuxConfig linux);
        pkgs.runCommand "shared-tmux-sesh"
          {
            nativeBuildInputs = [
              pkgs.python3
              linux.programs.tmux.package
            ];
          }
          ''
            export HOME="$TMPDIR/home"
            export SHELL=${pkgs.bash}/bin/bash
            mkdir -p "$HOME" "$TMPDIR/work tree"
            python3 - ${expected} ${linux.home.file.".config/sesh/sesh.toml".source} <<'PY'
            import json, sys, tomllib
            # Verify Home Manager's generated TOML, not just its evaluated settings.
            with open(sys.argv[1]) as f:
                expected = json.load(f)
            with open(sys.argv[2], 'rb') as f:
                assert tomllib.load(f) == expected
            PY

            # Private socket and scratch HOME: never touch the user's tmux server.
            socket="$TMPDIR/tmux.sock"
            trap 'tmux -S "$socket" kill-server 2>/dev/null || true' EXIT
            tmux -S "$socket" -f /dev/null \
              new-session -d -s smoke -c "$TMPDIR/work tree" '${pkgs.coreutils}/bin/sleep 60'
            # Upstream plugins retain /usr/bin/env shebangs, which exist on the
            # hosts but not inside a Nix build sandbox. Supply Bash explicitly
            # only for plugin launches in this sandbox copy of the real config.
            python3 - ${linux.xdg.configFile."tmux/tmux.conf".source} "$TMPDIR/tmux.conf" <<'PY'
            import re, sys
            from pathlib import Path
            config = Path(sys.argv[1]).read_text()
            config = re.sub(r'^run-shell (/nix/store/[^\n]+)$',
                            r'run-shell "${pkgs.bash}/bin/bash \1"', config, flags=re.M)
            Path(sys.argv[2]).write_text(config)
            PY
            tmux -S "$socket" source-file "$TMPDIR/tmux.conf" > "$TMPDIR/load.log" 2>&1
            cat "$TMPDIR/load.log"
            if grep -E "returned [1-9]|unknown (command|option)" "$TMPDIR/load.log"; then
              exit 1
            fi
            test "$(tmux -S "$socket" show-option -gv prefix)" = C-a
            test "$(tmux -S "$socket" show-option -gv @override_copy_command)" = '${pkgs.wl-clipboard}/bin/wl-copy'
            tmux -S "$socket" list-keys -T prefix o | grep 'sesh connect'
            tmux -S "$socket" list-keys -T prefix L | grep 'sesh last'
            tmux -S "$socket" list-keys -T prefix g | grep lazygit
            tmux -S "$socket" list-keys -T copy-mode-vi y | grep wl-copy
            touch "$out"
          '';
    };
}
