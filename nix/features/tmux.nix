{
  flake.homeModules.tmux =
    { pkgs, ... }:
    let
      themeRuntimePath =
        pkgs.lib.makeBinPath (
          with pkgs;
          [
            bash
            coreutils
            gnugrep
            gnused
            gawk
            bc
            git
            tmux
          ]
          ++ lib.optionals stdenv.hostPlatform.isLinux [ iproute2 ]
        )
        + pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ":/usr/bin:/bin:/usr/sbin:/sbin";
      tokyoNightTmux = pkgs.tmuxPlugins.mkTmuxPlugin {
        pluginName = "tokyo-night-tmux";
        version = "unstable-2025-12-20";
        src = pkgs.fetchFromGitHub {
          owner = "rollsrobby";
          repo = "tokyo-night-tmux";
          rev = "46cbf06e804b5e1bcfc53cc951f001dde5a47254";
          sha256 = "sha256-NuxgECOmwRtGHpCP5J5TZDHjT3Pwyn2gf2zMu5tnwgI=";
        };
        rtpFilePath = "tokyo-night.tmux";
        postPatch = ''
          # Every widget runs independently of the user's shell and Homebrew.
          for script in tokyo-night.tmux src/*.sh lib/*.sh; do
            substituteInPlace "$script" --replace-fail '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash
          export PATH=${themeRuntimePath}'
          done
          cat > lib/coreutils-compat.sh <<'EOF'
          # Runtime dependencies are supplied by Nix in every script.
          export PATH=${themeRuntimePath}
          EOF

          substituteInPlace tokyo-night.tmux \
            --replace-fail '#{pane_current_path}' '#{q:pane_current_path}'
          substituteInPlace src/path-widget.sh \
            --replace-fail 'echo ''${current_path}' 'echo "''${current_path}"'

          # Status refreshes must never fetch or otherwise access the network.
          substituteInPlace src/git-status.sh --replace-fail '    LAST_FETCH=$(stat -c %Y .git/FETCH_HEAD | bc)
              NOW=$(date +%s | bc)

              # if 5 minutes have passed since the last fetch
              if [[ $((NOW - LAST_FETCH)) -gt 300 ]]; then
                git fetch --atomic origin --negotiation-tip=HEAD
              fi
          ' ""
        '';
      };
    in
    {
      programs.tmux = {
        enable = true;
        sensibleOnTop = true;
        prefix = "C-a";
        keyMode = "vi";
        terminal = "tmux-256color";
        historyLimit = 100000;

        plugins = with pkgs.tmuxPlugins; [
          {
            plugin = yank;
            extraConfig = ''
              set -g @override_copy_command '${
                if pkgs.stdenv.hostPlatform.isDarwin then "/usr/bin/pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy"
              }'
            '';
          }
          vim-tmux-navigator
          {
            plugin = tokyoNightTmux;
            extraConfig = ''
              set -g @tokyo-night-tmux_theme night
              set -g @tokyo-night-tmux_transparent 1
              set -g @tokyo-night-tmux_show_datetime 0
              set -g @tokyo-night-tmux_window_id_style none
              set -g @tokyo-night-tmux_show_wbg 0
              set -g @tokyo-night-tmux_show_music 0
            '';
          }
        ];

        extraConfig = ''
          set-option -ga terminal-overrides ",xterm-256color:RGB"
          set -g base-index 1
          set -g detach-on-destroy off
          set -g renumber-windows on
          set -g mouse on
          setw -g mode-keys vi
          set -g automatic-rename on
          set -g extended-keys on 
          set -as terminal-features 'xterm*:extkeys'
          set -s theme terminal

          bind | split-window -c '#{pane_current_path}' -h
          bind - split-window -c '#{pane_current_path}' -v
          bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
          bind -r j resize-pane -D 2
          bind -r k resize-pane -U 2
          bind -r l resize-pane -R 2
          bind -r h resize-pane -L 2
          bind -r m resize-pane -Z
          bind -T copy-mode-vi v send -X begin-selection
          bind P paste-buffer
          bind x kill-pane
          bind -N "last-session (via sesh)" L run-shell "${pkgs.sesh}/bin/sesh last"
          bind -N "lazygit" g new-window -c '#{pane_current_path}' -n "🌳 git" "${pkgs.lazygit}/bin/lazygit 2> /dev/null"

        '';
      };
    };
}
