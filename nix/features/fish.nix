{
  flake.homeModules.fish =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.fish = {
        enable = true;

        # Shared aliases and environment come from Home Manager's home options.
        shellAbbrs = {
          gsls = "gs view -s";
        };

        # Select vi mode before integrations install their keybindings.
        interactiveShellInit = lib.mkBefore ''
          fish_vi_key_bindings
          set -g fish_color_command green
          set -g fish_color_quote yellow
          set -g fish_color_error red --bold
          set -g fish_color_param normal
          set -g fish_color_autosuggestion brblack
          ${pkgs.devenv}/bin/devenv hook fish | source
        '';

        functions = {
          h = ''
            $argv --help 2>&1 | bat -l help -p --paging=never
          '';

          sesh-sessions = ''
            set -l session (sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '> ')
            if test -n "$session"
              sesh connect "$session"
            end
            commandline -f repaint
          '';

          fish_user_key_bindings = ''
            for mode in default insert visual
              bind -M $mode \cr _atuin_search
              bind -M $mode \es sesh-sessions
            end
          '';
        };
      };

      programs.atuin.enableFishIntegration = true;
      programs.direnv.enableFishIntegration = true;
      programs.eza.enableFishIntegration = true;
      programs.fzf.enableFishIntegration = true;
      programs.yazi.enableFishIntegration = true;
      programs.zoxide.enableFishIntegration = true;
    };

  flake.nixosModules.fish = {
    programs.fish.enable = true;
  };
}
