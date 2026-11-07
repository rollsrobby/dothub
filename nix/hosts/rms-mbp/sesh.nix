{
  flake.homeModules.rmsMbpSesh =
    { config, ... }:
    let
      home = config.home.homeDirectory;
      repo = "${home}/nix-config";
    in
    {
      programs.sesh.settings.session = [
        {
          name = "Dotfiles";
          path = "${home}/dotfiles";
          startup_command = "nvim .";
        }
        {
          name = "Database";
          path = "${home}/tools/dbui";
          startup_command = "nvim -c ':DBUIToggle'";
        }
        {
          name = "sml dev";
          path = "${home}/code/sml/dev";
        }
        {
          name = "sml review";
          path = "${home}/code/sml/review";
        }
        {
          name = "hlb";
          path = "${home}/code/hlb-ws-app/dev";
        }
        {
          name = "sml-infra";
          path = "${home}/code/sml-infra/dev";
        }
        {
          name = "Portal";
          path = "${home}/code/sml-portal/dev";
        }
        {
          name = "gbm";
          path = "${home}/code/gbm";
        }
        {
          name = "http";
          path = "${home}/code/http";
          startup_command = "nvim .";
        }
        {
          name = "ghostty";
          path = "${home}/.config/ghostty";
          startup_command = "nvim .";
        }
        {
          name = "nvim";
          path = "${home}/.config/nvim";
          startup_command = "nvim .";
        }
        {
          name = "tmux";
          path = "${repo}";
          startup_command = "nvim modules/features/tmux.nix";
        }
        {
          name = "sesh";
          path = "${repo}";
          startup_command = "nvim modules/hosts/rms-mbp/sesh.nix";
        }
        {
          name = "nix-darwin";
          path = "${repo}";
          startup_command = "nvim modules/hosts/rms-mbp/system.nix";
        }
        {
          name = "Downloads";
          path = "${home}/Downloads";
          startup_command = "yazi";
        }
        {
          name = "notes";
          path = "${home}/code/notes";
          startup_command = "nvim .";
        }
        {
          name = "rms-pi-01";
          startup_command = "ssh rms@rms-pi-01";
        }
        {
          name = "pnp";
          path = "${home}/code/pnpcore";
        }
      ];
    };
}
